# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "GATK_Mutect"

class GATK_Mutect < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     normal_input_dir = <%= @opt_parser.get      from: 'normal_input_dir', default_value: '',         required: true,  type: String, comment: 'Input directory for Normal bam Samples' %>
     tumor_input_dir  = <%= @opt_parser.get      from: 'tumor_input_dir',  default_value: '',         required: true,  type: String, comment: 'Input directory for Tumoral bam Samples' %>
     input_files_name = <%= @opt_parser.get      from: 'input_name',       default_value: '',         required: true,  type: String, comment: 'name for input files (with sh regexp)' %>
     input_extension  = <%= @opt_parser.get      from: 'input_extension',  default_value: '',         required: true,  type: String, comment: 'Extension of inputs files without the dot separator' %>
     normal_tag       = <%= @opt_parser.get      from: 'normal_tag',       default_value: 'B',        required: true,  type: String, comment: 'extension to select input files' %>
     tumor_tag        = <%= @opt_parser.get      from: 'tumor_tag',        default_value: 'T',        required: true,  type: String, comment: 'extension to select Normal input files' %>
     output_dir       = <%= @opt_parser.get      from: 'output_dir',       default_value: 'output',   required: true,  type: String, comment: 'Output Directory' %>
     output_suffix    = <%= @opt_parser.get      from: 'output_suffix',    default_value: '_mutect',  required: false, type: String, comment: 'suffix for output files' %>
     ref_path         = <%= @opt_parser.get      from: 'ref_path',         default_value: '',         required: true,  type: String, comment: 'Genome reference' %>
     java_bin         = <%= @opt_parser.get      from: 'java_bin',         default_value: 'java',     required: false, type: String, comment: 'binary or Path/binary for java' %>
     mutect_jar       = <%= @opt_parser.get      from: 'mutect_jar',       default_value: '',         required: true,  type: String, comment: 'The Strelka binary with path' %>
     arg_java         = <%= @opt_parser.get_args from: 'java',             default_value: ['-Xmx4G'], comment: 'Argument send to Java' %>
     arg_gatk_mutect  = <%= @opt_parser.get_args from: 'mutect',           default_value: [],         comment: 'Argument for gatk RealignerTargetCreator' %>
    ~
  end

  def tool_template
    template = %~
      ## Inputs/Outputs
      #-- Inputs Templates    # .files_list take String or Array with files names or wildcard and return an Array of files
      files_list       = @datamanager.files_list( path_list: [normal_input_dir,tumor_input_dir], name_list: "\#{input_files_name}.\#{input_extension}") # find all input files
      @log.info(task_name) {" Collect input files \#{files_list.size} file(s) found"}
      sample_group_list= @datamanager.group_files( files_array: files_list, group_tags: [normal_tag, tumor_tag], check_group_size: true)             # group files by N or T tags
      @log.info(task_name) {" Creating groups with *\#{normal_tag}, *\#{tumor_tag}"}
      FileUtils.mkdir_p output_dir # Create the output_dir if it doesn't exist
      ## Step1: Realigner Target Creator
      for files in sample_group_list do
        # Input/Output
        base_name = files["id"]
        file_normal = files[normal_tag]
        file_tumor  = files[tumor_tag]
        now     = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        out_txt = "\#{output_dir}/\#{base_name}\#{output_suffix}.txt"
        out_vcf = "\#{output_dir}/\#{base_name}\#{output_suffix}.vcf"
        stdout  = "\#{output_dir}/\#{base_name}\#{output_suffix}_stdout-\#{now}.log"
        stderr  = "\#{output_dir}/\#{base_name}\#{output_suffix}_stderr-\#{now}.log"
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cd \#{project_path}; \#{java_bin} \#{arg_java} "
        cmd.line << "-jar \#{mutect_jar}"
        cmd.line << "--analysis_type MuTect"
        cmd.line << "--input_file:normal  \#{file_normal}"
        cmd.line << "--input_file:tumor   \#{file_tumor}"
        cmd.line << "--reference_sequence \#{ref_path}"
        cmd.line << "--out                \#{out_txt}"
        cmd.line << "-vcf                 \#{out_vcf}"
        cmd.line << "\#{arg_gatk_mutect}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        # - Error Test -
        if File.file?(out_txt) # if the file exist
          warning_list.push "\#{out_txt} output file is empty"  if File.size(out_txt)  == 0 # the size should be > 0
        else
          error_list.push "\#{out_txt} output file not found" # boolean
        end
        if File.file?(out_vcf) # if the file exist
          warning_list.push "\#{out_vcf} output file is empty"  if File.size(out_vcf)  == 0 # the size should be > 0
        else
          error_list.push "\#{out_vcf} output file not found" # boolean
        end
        # - Error Test -
      end
      # rm TMP
      `rm -rf \#{output_dir}/TMP`
    ~
  end

end
