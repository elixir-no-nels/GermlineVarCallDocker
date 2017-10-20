# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "GATK_IndelRealigner"

class GATK_IndelRealigner < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     input_dir     = <%= @opt_parser.get      from: 'input_dir',     default_value: '',       required: true,  type: String, comment: 'Input directory' %>
     input_files   = <%= @opt_parser.get      from: 'input_files',   default_value: '',       required: true,  type: String, comment: 'files to select as input files' %>
     ref_path      = <%= @opt_parser.get      from: 'ref_path',      default_value: '',       required: true,  type: String, comment: 'Genome reference (Fasta file with index)' %>
     output_dir    = <%= @opt_parser.get      from: 'output_dir',    default_value: 'output', required: true,  type: String, comment: 'Output Directory' %>
     output_suffix = <%= @opt_parser.get      from: 'output_suffix', default_value: 'output', required: true,  type: String, comment: 'suffix for output files' %>
     java_bin      = <%= @opt_parser.get      from: 'java_bin',      default_value: 'java',   required: false, type: String, comment: 'binary or Path/binary for java' %>
     gatk_jar      = <%= @opt_parser.get      from: 'gatk_jar',      default_value: 'GenomeAnalysisTK.jar',    required: false,  type: String,  comment: 'Path/file.jar for GATK' %>
     core          = <%= @opt_parser.get      from: 'core',          default_value: 1,        required: false, type: Integer, comment: 'Number of core to use' %>
     arg_java      = <%= @opt_parser.get_args from: 'java',          default_value: ['-Xmx4G'], comment: 'Argument send to Java' %>
     arg_gatk      = <%= @opt_parser.get_args from: 'gatk',          default_value: [],         comment: 'Argument for gatk (send to all gatk tools used in this step)' %>
     arg_gatk_rtc  = <%= @opt_parser.get_args from: 'gatk_realign_target_creator', default_value: [], comment: 'Argument for gatk RealignerTargetCreator' %>
     arg_gatk_realign = <%= @opt_parser.get_args from: 'gatk_indel_realigner',     default_value: [], comment: 'Argument for gatk IndelRealigner' %>
    ~
  end

  def tool_template
    template = %~
      ## Inputs/Outputs
      files_list = @datamanager.files_list( path_list: input_dir, name_list: "\#{input_files}")
      @log.info(task_name) {" Collect input files \#{files_list.size} file(s) found"}
      output_dir_name = output_dir
      output_dir = "\#{project_path}/\#{output_dir}"
      FileUtils.mkdir_p output_dir     # Create the output_dir if it doesn't exist
      ## Step1: Realigner Target Creator
      files  = files_list.join " -I "
      intervals = "\#{output_dir}/gatk_realign\#{output_suffix}.intervals"
      now    = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
      stdout = "\#{output_dir}/gatk_target_creation\#{output_suffix}_stdout-\#{now}.log"
      stderr = "\#{output_dir}/gatk_target_creation\#{output_suffix}_stderr-\#{now}.log"
      cmd = Command.new task_name: task_name, log: @log
      cmd.line << "cd \#{project_path}; \#{java_bin} \#{arg_java}"
      cmd.line << "-jar \#{gatk_jar}"
      cmd.line << "-T   RealignerTargetCreator"
      cmd.line << "-nt  \#{core}"
      cmd.line << "-R   \#{ref_path}"
      cmd.line << "-I   \#{files}"
      cmd.line << "-o   \#{intervals}"
      cmd.line << "\#{arg_gatk}"
      cmd.line << "\#{arg_gatk_rtc}"
      cmd.line << "> \#{stdout} 2> \#{stderr}"
      cmd.run compress_spaces: true, debug_mode: debug
      # - Error Test -
      if File.file?(intervals) # if the file exist
        if File.size(intervals) == 0 # the size should be > 0
          error_list.push "\#{intervals} output file is empty"
          @log.warn(task_name) {" the intermidiate file \#{intervals} created by RealignerTargetCreator is empty"}
        end
      else
        error_list.push "\#{intervals} output file not found" # boolean
        @log.warn(task_name) {" the intermidiate file \#{intervals} created by RealignerTargetCreator not found"}
      end
      # - Error Test -

      ## Step2: Prepair the map Input/Ouput mapping file
      ## because the map file system of GATK work only with relative execution path we use a "cd \#{project_path};" in the command
      map_file = File.open("\#{output_dir}/GATK_realignment_sample_paths.map", "w")
      for file in files_list
        #for the IndelRealigner tool (map input files to output files)
        map_file.puts "\#{File.basename file}\\t\#{output_dir_name}/\#{File.basename(file, ".*")}\#{output_suffix}.bam"
        @log.info(task_name) {"map \#{File.basename file} to \#{File.basename(file, ".*")}\#{output_suffix}.bam"}
      end
      map_file.close

      ## Step3: Realign Target Creator
      now    = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
      output = "\#{output_dir}/GATK_realignment_sample_paths.map"
      stdout = "\#{output_dir}/gatk_target_creation\#{output_suffix}_stdout-\#{now}.log"
      stderr = "\#{output_dir}/gatk_target_creation\#{output_suffix}_stderr-\#{now}.log"
      cmd = Command.new task_name: task_name, log: @log
      cmd.line << "cd \#{project_path}; \#{java_bin} \#{arg_java}"
      cmd.line << "-jar \#{gatk_jar}"
      cmd.line << "-T   IndelRealigner"
      cmd.line << "-R   \#{ref_path}"
      cmd.line << "-I   \#{files}"
      cmd.line << "-targetIntervals \#{intervals}"
      cmd.line << "-nWayOut \#{output}"
      cmd.line << "\#{arg_gatk}"
      cmd.line << "\#{arg_gatk_realign}"
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
    ~
  end

end
