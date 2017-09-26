# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "Sh"

class Sh < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
      input_dir        = <%= @opt_parser.get       from: 'input_dir',     default_value: '',        required: true, type: String, comment: 'Input directory' %>
      input_files      = <%= @opt_parser.get       from: 'input_files',   default_value: '',        required: true, type: String, comment: 'files to select as input files' %>
      output_dir       = <%= @opt_parser.get       from: 'output_dir',    default_value: 'output',  required: true, type: String, comment: 'Output Directory' %>
      output_suffix    = <%= @opt_parser.get       from: 'output_suffix', default_value: '_sorted', required: false, type: String, comment: 'Suffix for the output file' %>
      output_log       = <%= @opt_parser.get       from: 'output_log',    default_value: 'output',  required: true, type: String,  comment: 'Output Directory' %>
      bin              = <%= @opt_parser.get       from: 'bin',           default_value: '',        required: true, type: String,  comment: 'binary or Path/binary for java' %>
      arg_for_tool     = <%= @opt_parser.get_args  from: 'tool',          default_value: [],        comment: 'Argument for the Tool ' %>
    ~
  end

  def tool_template
    template = %~
      #-- Inputs Templates                                   # .files_list take String or Array with files names or wildcard and return an Array of files
      @log.info(task_name) {" Collect input files \#{files_list.size} file(s) found"}
      FileUtils.mkdir_p output_log                           # Create the output_dir if it doesn't exist
      ## Inputs/Outputs
      now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
      basename = File.basename(file, ".*")
      stdout   = "\#{output_log}/\#{bin}_stdout-\#{now}"
      stderr   = "\#{output_log}/\#{bin}_stderr-\#{now}"
      ## the actual samtools sort
      cmd = Command.new task_name: task_name, log: @log
      cmd.line << " \#{bin}"
      cmd.line << " \#{arg_for_tools}"
      cmd.line << " \#{file}"
      cmd.line << "> \#{stdout} 2> \#{stderr}"
      cmd.run compress_spaces: true, debug_mode: debug
    ~
  end

end
