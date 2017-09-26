require 'log.rb'
require 'tool_bases.rb'
require 'tool_modules_loader.rb'


# Create and Run a WorkFlow using Rake
class Workflow

  attr_accessor :debug

  # Initialize a Rake Application and some variables
  def initialize(module_list: false)
    fail('No module provided Workflow cannot be initialized') if module_list == false
    @module_list    = module_list            # take the list of loaded modules
    @info           = {}                     # Store Workflow general information
    @steps          = []                     # Store each step of the workflow
    @rakefiles_list = []                     # Store Rakefile for each step
    @final_steps    = []                     # used to build dependence tree
    @start_time     = Time.new.to_i          # Time 0 is fix here
    @debug          = false
    @app            = Rake.application       # The Rake application instance
    @app.init
  end

  # Load and parse configs file, start the log fom here
  # conf parsing use logs, logs start from parsing.
  def loadconfig(file: '')
    # main parsing
    config          = Configotron.new        # Class to parse config files
    config.load(file)                        # parse the config file
    parse_error     = self.parse config.data # parse info and populate @info and @steps objects, returns errors if problems
    check_error     = self.check_step @steps # check if all modules required are loaded
    fail('cannot find name or info in the configuration file') if @info['name'].nil?
    # initialise the Logging system from here
    log_dir         = './'
    log_dir         = @info['log_dir'] if not @info['log_dir'].nil?
    @log            = self.create_log id: @info['name'], log_dir: log_dir # Create The Log
    (@log.fatal { "Parsing configuration file : duplicate info section #{parse_error.to_s}" }; exit) if parse_error != []
    (@log.fatal { "Module #{check_error.to_s} not found" }; exit)                                    if check_error != []
    @log.info  "The Main workflow log is registered in  :  #{log_dir}"
    # The steps status
    @info['steps_status_dir'] = "steps_status" if @info['steps_status_dir'].nil?
    @info['steps_status_dir'] = @info['steps_status_dir'].sub(/\s/, '')
    @log.info  "The finished status of each steps is registered in :  #{@info['steps_status_dir']}"
  end

  # The Class used for logging
  def create_log id: '', log_dir: '', color: true
    FileUtils.mkdir_p log_dir
    header_name      = 'rbFlow'
    extension        = 'log'
    now              = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
    log_file_name    = File.expand_path("#{log_dir}/#{header_name}_#{id}_#{now}.#{extension}")
    log_file         = File.open(log_file_name,  'a')
    logger           = Logger_ext.new MultiDelegator.delegate(:write, :close).to(STDOUT, log_file)
    logger.level     = Logger::DEBUG
    logger.progname  = id
    logger.log_dir   = log_dir
    logger.datetime_format = '%d/%m/%Y\t%H:%M:%S'
    logger.formatter = proc do |severity, datetime, progname, msg|
      if color == true
        severity = severity.green     if severity == 'INFO'
        severity = severity.yellow    if severity == 'WARN'
        severity = severity.red       if severity == 'ERROR'
        severity = severity.red.bold  if severity == 'FATAL'
        severity = severity.magenta   if severity == 'DEBUG'
        severity = severity.blue.bold if severity == 'EXECUTE'
        severity = severity.blue      if severity == 'FINISH'
        progname = progname.bold
      end
      message  = ''
      message << "#{Time.new.to_i - @start_time}\t"
      message << "#{datetime}\t"
      message << "#{progname}\t"
      message << "#{severity}\t"
      message << "#{msg}\n"
      message
    end
    logger
  end

  # For each step describe in the configuration file, create a Rakefile and add it in the Rake Application
  def create_workflow
    @log.info "rbflow Version : #{RbFlow::VERSION}"
    @log.info "Creating the Workflow : [#{@info["name"]}]"
    for step_info in @steps.each do
      class_name = step_info['tool']                            # take the tool name in the config file
      identifier = step_info['id']                              # take the tool name in the config file
      @log.info "Create new Step : [#{identifier}] using [#{class_name}] Tool Module"
      task       = Kernel.const_get(class_name).new step_info: step_info, workflow_info: @info, log: @log # use it as a class name
      task.debug = @debug
      task.build_rake_step                                      # fill the Rake task template
      @final_steps.push step_info['id'] if task.result_to_get?  # used to build dependecies between Tasks
      @app.add_import  task.write_rake_step default: false      # add in the Rake @app the RakeFile with the current Task
    end
  end

  # write the default Rake Task as starting point of the workflow, with Results Task as depences
  def close_workflow
    self.check_result_list
    info = { 'depend_from' => @final_steps, 'id' => 'default_dynamic', 'step_options' => '', 'command_line_options' => '' }
    # WorkFlow for internal usage
    task = DefaultTask.new step_info: info, workflow_info: @info, log: @log # use it as a class name
    task.debug = @debug
    task.build_default_tasks                            # fill the Rake task with the default tasks template
    @app.add_import task.write_rake_step default: true  # add in the Rake @app the RakeFile with the current Task
    # WorkFlow for Rake invoking from shell
    info_s = { 'depend_from' => @final_steps, 'id' => 'default', 'step_options' => '', 'command_line_options' => '' }
    task_s = DefaultTaskStandAlone.new step_info: info_s, workflow_info: @info, log: @log # Write the StandAlone start point to restart the Workflow from bash
    task_s.debug = @debug
    task_s.build_default_tasks                          # fill the Rake task template for the StandAlone
    task_s.write_rake_step  default: true               # write the StandAlone
    task_s.copy_libs                                    # copy libraries for the standalone usage of rakefiles
    FileUtils.touch 'Rakefile'                          # create a Rakefile
    #FileUtils.ln_s("#{@info['name']}_default.rb", 'Rakefile', :force => true) # create a symbolic link from the main rake file as Rakefile but create a duplicate run in dynamic mode !!!
  end

  # Start the Rake Application
  def run
    @log.info "-----| Starting the Workflow : [#{@info["name"]}] |-----"
    # Loads the Rakefiles in the append list.
    @app.load_rakefile

    # Invoke the default Task giving instance of needed Classes as argument.
    # those Classes need to be initialized in default_task_standalone.rb
    # to be able to run the workflow as Standalone Rake
    datamanager = FileManager.new log: @log
    @app[:default].invoke(@log, datamanager)

    # puts "\n\nDependecies Tree"
    # puts "------------------------------"
    # @app.display_prerequisites
    # ap @app.tasks
    # puts "------------------------------\n\n"
  end

  #--------------- private

  # Basic Parsing of informations extracted from the config file
  def parse(data)
    step_count = 0
    info_count = 0
    error      = []
    data.each do |key, value|
      if key == 'workflow_steps'
        @steps = value
        step_count = step_count + 1
      elsif key == 'info'
        @info = value
        info_count = info_count + 1
      end
    end
    error.push 'Step section duplicated' if step_count > 1
    error.push 'Info section duplicated' if info_count > 1
    return error
  end

  # Check if the all modules requires fo all steps are present
  def check_step(data)
    check_error = []
    for step in data.each do
      class_name = step['tool']
      if not @module_list.include? class_name
        check_error.push class_name
      end
    end
    check_error
  end

  # return a array of step_id
  def step_id_list
    list = []
    for step in @steps.each do
      list.push step[id]
    end
  end

  # print to log the list of steps declare as result in the yaml configuration file
  # stop the workflow if no step are declare as result: "true"
  def check_result_list
    (@log.fatal { 'Workflow Finalisation : No Result Step found in The Configuration file' }; exit) if @final_steps.size == 0
    @log.info  'Workflow Finalisation : Dependence tree built to get result(s) for step(s) : '
    @final_steps.each do |result|
      @log.info "  - final steps id: #{result}"
    end
  end

  def close
    @log.close
  end

end
