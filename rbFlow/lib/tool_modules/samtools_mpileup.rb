# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "Samtools_Mpileup"

class Samtools_Mpileup < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     normal_input_dir = <%= @opt_parser.get      from: 'normal_input_dir', default_value: '',        required: true,  type: String, comment: 'Input directory for Normal bam Samples' %>
     tumor_input_dir  = <%= @opt_parser.get      from: 'tumor_input_dir',  default_value: '',        required: true,  type: String, comment: 'Input directory for Tumoral bam Samples' %>
     input_files_name = <%= @opt_parser.get      from: 'input_name',       default_value: '',        required: true,  type: String, comment: 'name for input files (with sh regexp)' %>
     input_extension  = <%= @opt_parser.get      from: 'input_extension',  default_value: '',        required: true,  type: String, comment: 'Extension of inputs files without the dot separator' %>
     normal_tag       = <%= @opt_parser.get      from: 'normal_tag',       default_value: 'B',       required: true,  type: String, comment: 'Tag to select Normal input files' %>
     tumor_tag        = <%= @opt_parser.get      from: 'tumor_tag',        default_value: 'T',       required: true,  type: String, comment: 'Tag to select Tumor  input files' %>
     output_dir       = <%= @opt_parser.get      from: 'output_dir',       default_value: 'output',  required: true,  type: String, comment: 'Output Directory' %>
     output_suffix    = <%= @opt_parser.get      from: 'output_suffix',    default_value: '',        required: false, type: String, comment: 'suffix for output files' %>
     output_extension = <%= @opt_parser.get      from: 'output_extension', default_value: 'mpileup', required: false, type: String, comment: 'Extension for output files' %>
     ref_path         = <%= @opt_parser.get      from: 'ref_path',         default_value: '',        required: true,  type: String, comment: 'Genome reference (Fasta file with index)' %>
     legacy           = <%= @opt_parser.get      from: 'legacy',           default_value: 'false',   required: false, type: String, comment: 'convert >=0.0.19 to 0.0.18 format, varscan2 use 0.0.18' %>
     arg_for_samtools = <%= @opt_parser.get_args from: 'samtools',         default_value: [],        comment: 'Argument for the Tool samtools sort' %>
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
        basename = files["id"]
        file_normal  = files[normal_tag]
        file_tumor   = files[tumor_tag]
        now          = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        output       = "\#{output_dir}/\#{basename}\#{output_suffix}.\#{output_extension}"
        stdout       = "\#{output_dir}/\#{basename}\#{output_suffix}_stdout-\#{now}"
        stderr       = "\#{output_dir}/\#{basename}\#{output_suffix}_stderr-\#{now}"
        inputs       = files[normal_tag] + " " + files[tumor_tag]
        normal_count = 1
        tumor_count  = 1
        ## Run samtools on normal bam file
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "samtools mpileup"
        cmd.line << "-f \#{ref_path}"
        cmd.line << "-B \#{inputs}"
        cmd.line << "\#{arg_for_samtools}"
        cmd.line << "| awk 'NF==9 && $4!=0' > \#{output}" if legacy == "false"
        cmd.line << "> \#{output}"                        if legacy == "true"
        cmd.line << "2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        # - Error Test -
        if File.file?(output) # if the file exist
          error_list.push "\#{output} output file is empty"  if File.size(output)  == 0 # the size should be > 0
        else
          error_list.push "\#{output} output file not found" # boolean
        end
        # - Error Test -

      end
    ~
  end

end
