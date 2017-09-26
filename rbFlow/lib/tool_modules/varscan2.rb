# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "VarScan2"

class VarScan2 < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     input_dir        = <%= @opt_parser.get      from: 'input_dir',       default_value: '',         required: true,  type: String, comment: 'Input directory' %>
     input_files_name = <%= @opt_parser.get      from: 'input_name',      default_value: '',         required: true,  type: String, comment: 'name for input files (with sh regexp)' %>
     input_extension  = <%= @opt_parser.get      from: 'input_extension', default_value: '',         required: true,  type: String, comment: 'Extension of inputs files without the dot separator' %>
     output_dir       = <%= @opt_parser.get      from: 'output_dir',      default_value: 'output',   required: true,  type: String, comment: 'Output Directory' %>
     output_suffix    = <%= @opt_parser.get      from: 'output_suffix',   default_value: '_varscan2', required: false, type: String, comment: 'Suffix for the output file' %>
     varscan2_jar     = <%= @opt_parser.get      from: 'varscan2_jar',    default_value: '',         required: true,  type: String, comment: 'path/binary.jar for varscan2' %>
     java_bin         = <%= @opt_parser.get      from: 'java_bin',        default_value: 'java',     required: false, type: String, comment: 'binary or Path/binary for java' %>
     arg_java         = <%= @opt_parser.get_args from: 'java',            default_value: ['-Xmx4G'], comment: 'Argument send to Java' %>
     arg_for_varscan2 = <%= @opt_parser.get_args from: 'varscan2',        default_value: [],         comment: 'Argument for the Tool picard' %>
    ~
  end

  def tool_template
    template = %~
      #-- Inputs Templates                                   # .files_list take String or Array with files names or wildcard and return an Array of files
      files_list = @datamanager.files_list( path_list: input_dir, name_list: "\#{input_files_name}.\#{input_extension}")
      FileUtils.mkdir_p output_dir                           # Create the output_dir if it doesn't exist

      ## Inputs/Outputs
      for file in files_list do
        now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        basename = File.basename(file, ".*")

        # Search for a base_name.ratio file in the input directory
        ratio      = ''
        cmd        = ''
        ratio_file = "\#{input_dir}/\#{basename}.ratio"
        if File.file?(ratio_file)  # if the ratio file exist
          cmd   = `cat \#{ratio_file}`
          ratio = " --data-ratio " + cmd
          @log.info(task_name) {"found \#{ratio_file} with ratio : \#{ratio}"}
        else
          @log.warn(task_name) {"no ratio found (mpileup file and ratio file should have the same basename): \#{ratio_file}"}
        end

        ## Running VarScan2 copynumber
        output   = "\#{output_dir}/\#{basename}" # varscan2 will add the .copynumber extention itself
        stdout   = "\#{output_dir}/\#{basename}\#{output_suffix}_copynumber_stdout-\#{now}.log"  #"
        stderr   = "\#{output_dir}/\#{basename}\#{output_suffix}_copynumber_stderr-\#{now}.log"  #"
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cd \#{project_path}; \#{java_bin} \#{arg_java} "
        cmd.line << "-jar \#{varscan2_jar} copynumber"
        cmd.line << "\#{file}"
        cmd.line << "\#{output}"
        cmd.line << "\#{arg_for_varscan2}"
        cmd.line << "--mpileup 1"
        cmd.line << "\#{ratio}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        # - Error Test -
        if File.file?("\#{output}.copynumber") # if the file exist
          if File.size("\#{output}.copynumber") == 0 # the size should be > 0
            error_list.push "\#{output} output file is empty"
            @log.warn(task_name) {" the intermidiate file \#{output}.copynumber created by varscan2 copynumber is empty"}
          end
        else
          error_list.push "\#{output} output file not found" # boolean
          @log.warn(task_name) {" the intermidiate file \#{output}.copynumber created by varscan2 copynumber not found"}
        end
        # - Error Test -


        ## Running VarScan2 copyCaller
        input    = "\#{output_dir}/\#{basename}.copynumber"
        output   = "\#{output_dir}/\#{basename}.copyCaller"
        stdout   = "\#{output_dir}/\#{basename}\#{output_suffix}_copycaller_stdout-\#{now}.log"  #"
        stderr   = "\#{output_dir}/\#{basename}\#{output_suffix}_copycaller_stderr-\#{now}.log"  #"
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cd \#{project_path}; java \#{arg_java} "
        cmd.line << "-jar \#{varscan2_jar} copyCaller"
        cmd.line << "\#{input}"
        cmd.line << "--output-file \#{output}.called"
        cmd.line << "--output-homdel-file \#{output}.called.homdel"
        cmd.line << "\#{arg_for_varscan2}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        # - Error Test -
        if File.file?("\#{output}.called") # if the file exist
          warning_list_list.push "\#{output}.called output file is empty" if File.size("\#{output}.called") == 0 # the size should be > 0
          @log.warn(task_name) {" the intermidiate file \#{output}.called created by varscan2 copyCaller is empty"}
        else
          error_list.push "\#{output}.called output file not found" # boolean
          @log.warn(task_name) {" the intermidiate file \#{output}.called created by varscan2 copyCaller not found"}
        end
        if File.file?("\#{output}.called.homdel") # if the file exist
          warning_list_list.push "\#{output}.called.homdel output file is empty" if File.size("\#{output}.called.homdel") == 0 # the size should be > 0
          @log.warn(task_name) {" the intermidiate file \#{output}.called.homdel created by varscan2 copyCaller is empty"}
        else
          error_list.push "\#{output}.called.homdel output file not found" # boolean
          @log.warn(task_name) {" the intermidiate file \#{output}.called.homdel created by varscan2 copyCaller not found"}
        end
        # - Error Test -

        # rm TMP
        `rm -rf \#{output_dir}/TMP`
      end
    ~
  end

end
