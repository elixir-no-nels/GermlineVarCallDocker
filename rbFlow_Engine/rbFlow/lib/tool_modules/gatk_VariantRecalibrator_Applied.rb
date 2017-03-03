# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "GATK_VariantRecalibratorApplied"

class GATK_VariantRecalibratorApplied < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     input_dir      = <%= @opt_parser.get      from: 'input_dir',     default_value: '',       required: true,  type: String,  comment: 'Input directory' %>
     input_files    = <%= @opt_parser.get      from: 'input_files',   default_value: '',       required: true,  type: String,  comment: 'files to select as input files' %>
     ref_path       = <%= @opt_parser.get      from: 'ref_path',      default_value: '',       required: true,  type: String,  comment: 'Genome reference (Fasta file with index)' %>
     output_dir     = <%= @opt_parser.get      from: 'output_dir',    default_value: 'output', required: true,  type: String,  comment: 'Output Directory' %>
     output_suffix  = <%= @opt_parser.get      from: 'output_suffix', default_value: '_Recal', required: true,  type: String, comment: 'suffix for output files' %>
     java_bin       = <%= @opt_parser.get      from: 'java_bin',      default_value: 'java',   required: false, type: String, comment: 'binary or Path/binary for java' %>
     gatk_jar       = <%= @opt_parser.get      from: 'gatk_jar',      default_value: 'GenomeAnalysisTK.jar',    required: false,  type: String,  comment: 'Path/file.jar for GATK' %>
     core           = <%= @opt_parser.get      from: 'core',          default_value: 1,        required: false, type: Integer, comment: 'Number of core to use' %>
     arg_java       = <%= @opt_parser.get_args from: 'java',          default_value: ['-Xmx4G'], comment: 'Argument send to Java' %>
     arg_gatk       = <%= @opt_parser.get_args from: 'gatk',          default_value: [],         comment: 'Argument for gatk (send to all gatk tools used in this step)' %>
     mode           = <%= @opt_parser.get      from: 'mode',          default_value: '',       required: true, type: String, comment: 'SNP/INDEL/BOTH' %>
     arg_gatk_vr    = <%= @opt_parser.get_args from: 'gatk_vr',       default_value: [],         comment: 'Argument for gatk VariantRecalibrator' %>
     arg_gatk_ar    = <%= @opt_parser.get_args from: 'gatk_ar',       default_value: [],         comment: 'Argument for gatk ApplyRecalibration' %>
    ~
  end

  def tool_template
    template = %~
      ## Test some Args needed
      # mode is it valid ?
      error_list.push 'mode must be [INDEL|SNP|BOTH]' if not ['INDEL','SNP','BOTH'].include? mode
      # do we have at least one '-resource' option ?
      error_list.push 'set at least a -resource in the gatk_vr field' if not arg_gatk_vr.include? '-resource'
      # do we have  at least a '-an' option ('--use_annotation' is replaced by the short '-an' version )
      arg_gatk_vr.gsub!('--use_annotation ','-an ')
      error_list.push 'set at least a --use_annotation or -an in the gatk_vr field' if not arg_gatk_vr.include? '-an '

      ## Inputs/Outputs
      input_files = @datamanager.files_list( path_list: input_dir, name_list: "\#{input_files}")
      @log.info(task_name) {" Collect input files \#{input_files.size} file(s) found"}
      output_dir_name = output_dir
      output_dir = "\#{project_path}/\#{output_dir}"
      FileUtils.mkdir_p output_dir     # Create the output_dir if it doesn't existd
      for file in input_files do
        basename = File.basename(file, ".*")
        recalFile   = "\#{output_dir}/\#{basename}\#{output_suffix}.recal"
        trancheFile = "\#{output_dir}/\#{basename}\#{output_suffix}.tranches"
        ### Step1: Realign Target Creator command
        now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        stdout   = "\#{output_dir}/\#{basename}_VarRecal\#{output_suffix}_stdout-\#{now}.log"
        stderr   = "\#{output_dir}/\#{basename}_VarRecal\#{output_suffix}_stderr-\#{now}.log"

        ## Step1: Base Recalibrator command
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cd     \#{project_path}; \#{java_bin} \#{arg_java} "
        cmd.line << "-jar   \#{gatk_jar}"
        cmd.line << "-T     VariantRecalibrator"
        cmd.line << "-nt    \#{core}"
        cmd.line << "-R     \#{ref_path}"
        cmd.line << "-input \#{file}"
        cmd.line << "-mode  \#{mode}"
        cmd.line << "-recalFile    \#{recalFile}"
        cmd.line << "-tranchesFile \#{trancheFile}"
        cmd.line << "  \#{arg_gatk}"
        cmd.line << "  \#{arg_gatk_vr}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        # - Error Test -
        if File.file?(recalFile) # if the file exist
          if File.size(recalFile) == 0 # the size should be > 0
            error_list.push "\#{recalFile} output file is empty"
            @log.warn(task_name) {" the intermidiate file \#{recalFile} created by VariantRecalibrator is empty"}
          end
        else
          error_list.push "\#{recalFile} output file not found" # boolean
          @log.warn(task_name) {" the intermidiate file \#{recalFile} created by VariantRecalibrator not found"}
        end
        # - Error Test -
        ## Step2: ApplyRecalibration
        now    = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        output = "\#{output_dir}/\#{basename}\#{output_suffix}.vcf"
        stdout = "\#{output_dir}/\#{basename}_ApplyRecal\#{output_suffix}_stdout-\#{now}.log"
        stderr = "\#{output_dir}/\#{basename}_ApplyRecal\#{output_suffix}_stderr-\#{now}.log"
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cd     \#{project_path}; \#{java_bin} \#{arg_java} "
        cmd.line << "-jar   \#{gatk_jar}"
        cmd.line << "-T     ApplyRecalibration"
        cmd.line << "-nt    \#{core}"
        cmd.line << "-R     \#{ref_path}"
        cmd.line << "-input \#{file}"
        cmd.line << "-mode  \#{mode}"
        cmd.line << "-recalFile    \#{recalFile}"
        cmd.line << "-tranchesFile \#{trancheFile}"
        cmd.line << "-o \#{output}"
        cmd.line << "   \#{arg_gatk}"
        cmd.line << "   \#{arg_gatk_ar}"
        cmd.line << ">  \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug

        # - Error Test -
        if File.file?(output) # if the file exist
          error_list.push "\#{output} output file is empty"  if File.size(output)  == 0 # the size should be > 0
        else
          error_list.push "\#{output} output file not found" # boolean
        end
        # - Error Test -
      end

      # rm TMP
      `rm -rf \#{output_dir}/TMP`
    ~
  end

end
