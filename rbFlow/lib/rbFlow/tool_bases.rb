require 'config.rb'
require 'files_manager.rb'
require 'command.rb'
require 'tool_options.rb'
require 'tool_templates'
require 'erb'

# Base Class used to create a Step for Rake (used as parent for tool specific class (called Tool Modules))
# Each Tool Modules herit from this class and define a specific step_template function containing the Template for the Rake Task
#
# can be use to have clean name for Tasks  (Ruby >= 2.1)
# http://www.ruby-doc.org/core-2.1.0/Regexp.html#class-Regexp-label-Character+Properties
#  .downcase.gsub(/[^\p{Alnum}-]/, '_')
class Toolbase
  include Templates

  attr_accessor :debug

  # Some initialisation   step: step, log: @log, info: @info
  def initialize(step_info: '', workflow_info: '', log: '')
    # check error
    error = ''
    error = error + ' step_options'         if step_info['step_options'].nil?
    error = error + ' command_line_options' if step_info['command_line_options'].nil?
    # General Informations
    @log          = log                              # current log instance
    @rake_task    = ""                               # to Store the code build for the rake task of the step
    @workflow_id  = workflow_info['name'].sub(/\s/, '')
    @task_name    = step_info['id']
    @description  = step_info['desc']
    @depedencies  = step_info['depend_from']          if not step_info['depend_from'].nil?
    @result       = step_info['result']               if not step_info['result'].nil?
    @options      = {}
    @options      = step_info                        # Informations for this Step Task (hash)
    @opt_parser   = ToolOptions.new from: @options, name: @task_name, log: @log   # Class Used to parse and check options
    @arguments    = {}
    @arguments    = step_info['command_line_options'] # Informations for command lines tools (hash of array)
    @project_path = Dir.pwd + '/'
    @debug        = false
    @libdir       = 'lib'                             # used to as destination dir to copy libraries used to run the workflow as a standalone RakeFile
    @step_status_dir = workflow_info['steps_status_dir'] 

    (@log.fatal { "Step Init error, Section Info not found (Check the yaml indentation) : #{error}" }; exit ) if error != ''
    @log.info "Init Rake Step  : [#{@task_name}] with [#{self.class.name}] Tool Module"
  end

  # Create a Rake Task Script with Generics and Task Specifics Templates
  def build_rake_step
    @rake_task << self.global_config                     # Open the rake Stek and get General Configuration information
    @rake_task << (self.render self.get_config_template) # get Specific Configuration. Defined in the [tool].rb module file (erb)
    @opt_parser.check_error                              # stop here if errors found in the configuration
    @rake_task << self.test_validation                   # step is already done ?      Defined in the tool_template.rb file
    @rake_task << (self.render self.tool_template)       # get specific Task Code.     Defined in the [tool].rb module file (erb)
    @rake_task << self.write_validation                  # write the check file        Defined in the tool_template.rb file
    @rake_task << self.close_step                        # To close the rake Step      Defined in the tool_template.rb file
  end

  # Fill the Rake Task Script with Generics and Task Specifics Templates
  def build_default_tasks
    @rake_task << self.step_template       # get General Configuration information
  end

  # check if this step is a final result
  def result_to_get?
    if not @result.nil?
      if @result.downcase == 'true'
        return true
      else
        return false
      end
    else
      return false
    end
  end

  # Write the Rakefile with the Task for the current Step
  def write_rake_step(default: false)
    prefix = @workflow_id + '_'
    prefix = prefix + 'task_' if not default
    if @rake_task == false
      @log.fatal { 'No Rake Task defined' }; exit
    else
      file_out = "#{prefix}#{@task_name}.rb"
      dest = File.open(file_out, 'w') # a = append
      dest.puts @rake_task
      dest.close
      @log.info "Write Rake Step : [#{@task_name}] in [#{file_out}]"
      return @project_path + '/' + file_out
    end
  end

  # Format the dependencies list for the rake Task.
  def add_depend_list
    list = ''
    if @depedencies.nil? or @depedencies.size == 0
      list = ''
    elsif @depedencies.class == String
      list = "=> [:#{@depedencies}] "
    elsif @depedencies.class == Array
      list = '=> [ '
      need_comma = false
      for element in @depedencies
        list = list + ', ' if need_comma
        list = list + ":#{element}"
        @log.info "  - dependent from : #{element}"
        need_comma = true
      end
      list = list + ' ] '
    else
      @log.fatal { "Cannot parse dependencies [#{@depedencies}]" }; exit
    end
    return list
  end

  # Copy some requirement file used to run the workflow from Rakefile with rake command
  def copy_libs
    path_to_original_lib = File.dirname(__FILE__)          # File.dirname(__FILE__)  is the location of this file, that give the path of the main lib folder
    libs_to_copy         = ['log.rb', 'files_manager.rb', 'command.rb'] # List of Libraries copied in the project folder for standalone run
    libs_dest_dir        = "#{@project_path}/#{@libdir}"   # Dir used to store libraries, to run the rakefile
    lib_dir              = File.expand_path(libs_dest_dir) # get the absolute path
    FileUtils.mkdir_p libs_dest_dir                        # Create the output_dir if it doesn't exist
    for lib in libs_to_copy
      lib_file =  "#{path_to_original_lib}/#{lib}"
      (@log.fatal { "Workflow Finalisation : cannot copy the library #{lib_file} " }; exit ) if not File.file? lib_file
      @log.info  "Workflow Finalisation : Copy libraries for a standalone usage of the rakefiles : #{lib_file}"
      FileUtils.cp "#{lib_file}", libs_dest_dir
    end
  end

  # render template with ERB
  def render(template)
    b    = binding
    code = ERB.new template
    code.result b
  end

end
