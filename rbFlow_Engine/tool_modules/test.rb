# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "Test"

class Test < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     input_dir     = <%= @opt_parser.get      from: 'input_dir',    default_value: 'input',  required: true,  type: String, comment: 'Input directory' %>
     output_dir    = <%= @opt_parser.get      from: 'output_dir',   default_value: 'output', required: true,  type: String, comment: 'Output Directory' %>
     input_tag_1   = <%= @opt_parser.get      from: 'input_tag_1',  default_value: '',       required: true,  type: String, comment: 'A string use as filter to select files' %>
     input_tag_2   = <%= @opt_parser.get      from: 'input_tag_2',  default_value: '',       required: true,  type: String, comment: 'A string use as filter to select files' %>
     wait_time     = <%= @opt_parser.get      from: 'wait_time',    default_value: 1,        required: true,  type: Fixnum, comment: 'Time to wait to simulate a long process' %>
     create_warn   = <%= @opt_parser.get      from: 'create_warn',  default_value: '',       required: false, type: String, comment: 'Create a warning with this message' %>
     create_error  = <%= @opt_parser.get      from: 'create_error', default_value: '',       required: false, type: String, comment: 'Create an error with this message' %>
     arg_for_tool1 = <%= @opt_parser.get_args from: 'tool1',        default_value: [],       comment: 'Argument for the Tool Tool1' %>
    ~
  end

  def tool_template
    template = %~
      #-- Inputs Templates                                          # .files_list take String or Array with files names or wildcard and return an Array of files
      input_files1 = @datamanager.files_list( path_list: input_dir, name_list: input_tag_1)
      input_files2 = @datamanager.files_list( path_list: input_dir, name_list: input_tag_2)
      FileUtils.mkdir_p output_dir                                  # Create the output_dir if it doesn't exist

      @log.info(task_name) {"Test Args given for tool1 are : \#{arg_for_tool1}"}
      @log.info(task_name) {"Arg given for wait_time : \#{wait_time} second(s)"}
      #-- Commands

      # Copy files with tag 1 from input dir to output dir
      for file in input_files1
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cp \#{file} \#{output_dir} "
        cmd.line << " >> \#{output_dir}/tool1_\#{now}_stdout.log 2>> \#{output_dir}/tool1_\#{now}_stderr.log"
        cmd.run compress_spaces: true, debug_mode: debug
      end

      # Copy files with tag 2 from input dir to output dir
      for file in input_files2
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cp \#{file} \#{output_dir} "
        cmd.line << " >> \#{output_dir}/tool2_\#{now}_stdout.log 2>> \#{output_dir}/tool2_\#{now}_stderr.log"
        cmd.run compress_spaces: true
      end

      # get std and err out and the pid
      cmd = Command.new task_name: task_name, log: @log
      cmd.line << "date "
      cmd.run compress_spaces: true, debug_mode: debug
      out = cmd.captured_stdout
      err = cmd.captured_stderr
      pid = cmd.pid
      @log.info(task_name) {"Std output : \#{out.chomp}"} if not debug
      @log.info(task_name) {"Std error  : \#{err}"}       if not debug
      @log.info(task_name) {"pid        : \#{pid}"}       if not debug
      @log.info(task_name) {"Debug Mode"}           if debug

      # Wait
      cmd = Command.new task_name: task_name, log: @log
      cmd.line << "sleep \#{wait_time} "
      cmd.run compress_spaces: true, debug_mode: debug

      ## Error Test
      ## Usually by testing outputs, classics test could be
      # error_list.push "\#{output} output file not found" if File.directory?(output)  == false
      # error_list.push "\#{output} output file not found" if File.size(output)    == 0      # 2766
      # warning_list.push "\#{output} output file is empty"  if File.file?(output) == false  # true
      error_list.push   "Error test message   : \#{create_error} " if create_error != ''      # 27662
      warning_list.push "Warning test message : \#{create_warn}  " if create_warn  != ''

    ~
  end

end
