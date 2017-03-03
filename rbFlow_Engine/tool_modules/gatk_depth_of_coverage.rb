# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "GATK_DepthOfCoverage"

class GATK_DepthOfCoverage < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     input_dir      = <%= @opt_parser.get      from: 'input_dir',     default_value: '',       required: true,  type: String, comment: 'Input directory' %>
     input_files    = <%= @opt_parser.get      from: 'input_files',   default_value: '',       required: true,  type: String, comment: 'files to select as input files' %>
     ref_path       = <%= @opt_parser.get      from: 'ref_path',      default_value: '',       required: true,  type: String, comment: 'Genome reference (Fasta file with index)' %>
     output_dir     = <%= @opt_parser.get      from: 'output_dir',    default_value: 'output', required: true,  type: String, comment: 'Output Directory' %>
     output_suffix  = <%= @opt_parser.get      from: 'output_suffix', default_value: '_DOC',   required: true,  type: String, comment: 'suffix for output files' %>
     java_bin       = <%= @opt_parser.get      from: 'java_bin',      default_value: 'java',   required: false, type: String, comment: 'binary or Path/binary for java' %>
     gatk_jar       = <%= @opt_parser.get      from: 'gatk_jar',      default_value: 'GenomeAnalysisTK.jar',    required: false,  type: String,  comment: 'Path/file.jar for GATK' %>
     core           = <%= @opt_parser.get      from: 'core',          default_value: 1,        required: false, type: Integer, comment: 'Number of core to use' %>
     arg_java       = <%= @opt_parser.get_args from: 'java',          default_value: ['-Xmx4G'],   comment: 'Argument send to Java' %>
     arg_gatk       = <%= @opt_parser.get_args from: 'gatk',          default_value: [],           comment: 'Argument for gatk (send to all gatk tools used in this step)' %>
     arg_gatk_doc   = <%= @opt_parser.get_args from: 'gatk_DepthOfCoverage',    default_value: [], comment: 'Argument for gatk DepthOfCoverage' %>
    ~
  end

  def tool_template
    template = %~
      ## Inputs/Outputs
      input_files = @datamanager.files_list( path_list: input_dir, name_list: "\#{input_files}")
      @log.info(task_name) {" Collect input files \#{input_files.size} file(s) found"}
      output_dir_name = output_dir
      output_dir = "\#{project_path}/\#{output_dir}"
      FileUtils.mkdir_p output_dir     # Create the output_dir if it doesn't exist
      for file in input_files do
        basename = File.basename(file, ".*")
        group    = "\#{output_dir}/\#{basename}\#{output_suffix}.grp"
        ### Step1: DepthOfCoverage
        now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        stdout   = "\#{output_dir}/\#{basename}\#{output_suffix}_stdout-\#{now}.log"
        stderr   = "\#{output_dir}/\#{basename}\#{output_suffix}_stderr-\#{now}.log"

        ## Step1: DepthOfCoverage command
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cd \#{project_path}; \#{java_bin} \#{arg_java} "
        cmd.line << "-jar \#{gatk_jar}"
        cmd.line << "-T   DepthOfCoverage "
        cmd.line << "-nct  \#{core}"
        cmd.line << "-R   \#{ref_path}"
        cmd.line << "-I   \#{file}"
        cmd.line << "-o   \#{group}"
        cmd.line << "\#{arg_gatk}"
        cmd.line << "\#{arg_gatk_doc}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        # - Error Test -
        if File.file?(group+".sample_summary") # if the file exist
          error_list.push "\#{group}.sample_summary output file is empty"  if File.size(group+".sample_summary")  == 0 # the size should be > 0
        else
          error_list.push "\#{group}.sample_summary output file not found" # boolean
        end
        # - Error Test -
      end

      # rm TMP
      `rm -rf \#{output_dir}/TMP`
    ~
  end

end
