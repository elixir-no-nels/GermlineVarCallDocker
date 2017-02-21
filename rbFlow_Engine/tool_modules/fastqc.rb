# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "FastQC"

class FastQC < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     input_dir   = <%= @opt_parser.get      from: 'input_dir',   default_value: '', required: true, type: String, comment: 'Input directory' %>
     input_files = <%= @opt_parser.get      from: 'input_files', default_value: '', required: true, type: String, comment: 'files to select as input files' %>
     output_dir  = <%= @opt_parser.get      from: 'output_dir',  default_value: '', required: true, type: String, comment: 'Output Directory' %>
     fastqc_bin  = <%= @opt_parser.get      from: 'fastqc_bin',  default_value: '', required: true, type: String, comment: 'binary or Path/binary for fastqc' %>
     arg_fastqc  = <%= @opt_parser.get_args from: 'fastqc',      default_value: [], comment: 'Argument for the Tool samtools sort' %>
    ~
  end

  def tool_template
    template = %~
      #-- Inputs Templates                                   # .files_list take String or Array with files names or wildcard and return an Array of files
      files_list = @datamanager.files_list( path_list: input_dir, name_list: "\#{input_files}")          # find all input files
      @log.info(task_name) {" Collect input files \#{files_list.size} file(s) found"}
      FileUtils.mkdir_p output_dir                           # Create the output_dir if it doesn't exist
      ## Inputs/Outputs
      for file in files_list
        now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        basename = File.basename(file, ".*")
        output   = "\#{output_dir}/\#{basename}"
        FileUtils.mkdir_p output
        stdout   = "\#{output_dir}/\#{basename}_stdout-\#{now}"
        stderr   = "\#{output_dir}/\#{basename}_stderr-\#{now}"
        ## the actual fastqc sort
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "\#{fastqc_bin}"
        cmd.line << "--outdir \#{output}"
        cmd.line << "\#{arg_fastqc}"
        cmd.line << "\#{file}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        # - Error Test -
        error_list.push "\#{output} output file not found" if File.directory?(output)  == false
      end
    ~
  end

end
