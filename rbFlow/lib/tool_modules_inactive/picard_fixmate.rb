# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "PicardFixMate"

class PicardFixMate < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     input_dir        = <%= @opt_parser.get      from: 'input_dir',    default_value: '',         required: true,  type: String, comment: 'Input directory' %>
     input_files      = <%= @opt_parser.get      from: 'input_files',  default_value: '',         required: true,  type: String, comment: 'files to select as input files' %>
     output_dir       = <%= @opt_parser.get      from: 'output_dir',   default_value: 'output',   required: true,  type: String, comment: 'Output Directory' %>
     output_suffix    = <%= @opt_parser.get      from: 'output_suffix',default_value: '_fixmate', required: false, type: String, comment: 'Suffix for the output file' %>
     picard_path      = <%= @opt_parser.get      from: 'picard_path',  default_value: '',         required: true,  type: String, comment: 'Path for the jar directory of Picard' %>
     java_bin         = <%= @opt_parser.get      from: 'java_bin',     default_value: 'java',     required: false, type: String, comment: 'binary or Path/binary for java' %>
     arg_java         = <%= @opt_parser.get_args from: 'java',         default_value: ['-Xmx4G'], comment: 'Argument send to Java' %>
     arg_for_picard   = <%= @opt_parser.get_args from: 'picard',       default_value: [],         comment: 'Argument for the Tool picard' %>
    ~
  end

  def tool_template
    template = %~
      #-- Inputs Templates                                   # .files_list take String or Array with files names or wildcard and return an Array of files
      files_list = @datamanager.files_list( path_list: input_dir, name_list: "\#{input_files}")
      @log.info(task_name) {" Collect input files \#{files_list.size} file(s) found"}
      FileUtils.mkdir_p output_dir                           # Create the output_dir if it doesn't exist
      ## Inputs/Outputs
      for file in files_list do
        now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        basename = File.basename(file, ".*")
        output   = "\#{output_dir}/\#{basename}\#{output_suffix}.bam"
        stdout   = "\#{output_dir}/\#{basename}\#{output_suffix}_stdout-\#{now}.log"  #"
        stderr   = "\#{output_dir}/\#{basename}\#{output_suffix}_stderr-\#{now}.log"  #"
        ## the actual picard Fix Mate
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cd \#{project_path}; \#{java_bin} \#{arg_java} "
        cmd.line << "-jar \#{picard_path}/FixMateInformation.jar"
        cmd.line << "INPUT=\#{file}"
        cmd.line << "\#{arg_for_picard}"
        cmd.line << "OUTPUT=\#{output}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        # - Error Test -
        if File.file?(output) # if the file exist
          error_list.push "\#{output} output file is empty"  if File.size(output)  == 0 # the size should be > 0
        else
          error_list.push "\#{output} output file not found" # boolean
        end
        # - Error Test -

        # rm TMP
        `rm -rf \#{output_dir}/TMP`
      end
    ~
  end

end
