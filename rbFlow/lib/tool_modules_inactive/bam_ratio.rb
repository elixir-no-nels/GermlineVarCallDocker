# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "BamRatio"

class BamRatio < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     normal_input_dir = <%= @opt_parser.get      from: 'normal_input_dir', default_value: '',        required: true,  type: String, comment: 'Input directory for Normal bam Samples' %>
     tumor_input_dir  = <%= @opt_parser.get      from: 'tumor_input_dir',  default_value: '',        required: true,  type: String, comment: 'Input directory for Tumoral bam Samples' %>
     input_files_name = <%= @opt_parser.get      from: 'input_name',       default_value: '',        required: true,  type: String, comment: 'name for input files (with sh regexp)' %>
     input_extension  = <%= @opt_parser.get      from: 'input_extension',  default_value: '',        required: true,  type: String, comment: 'Extension of inputs files without the dot separator' %>
     samtools_bin     = <%= @opt_parser.get      from: 'samtools_bin',     default_value: 'samtools',required: false,  type: String, comment: 'binary or Path/binary for samtools' %>
     normal_tag       = <%= @opt_parser.get      from: 'normal_tag',       default_value: 'B',       required: true,  type: String, comment: 'extension to select input files' %>
     tumor_tag        = <%= @opt_parser.get      from: 'tumor_tag',        default_value: 'T',       required: true,  type: String, comment: 'extension to select Normal input files' %>
     output_dir       = <%= @opt_parser.get      from: 'output_dir',       default_value: 'output',  required: true,  type: String, comment: 'Output Directory' %>
     output_suffix    = <%= @opt_parser.get      from: 'output_suffix',    default_value: '',        required: false, type: String, comment: 'suffix for output files' %>
     core             = <%= @opt_parser.get      from: 'core',             default_value: 1,         required: false, type: Integer, comment: 'Number of core to use' %>
     arg_for_samtools = <%= @opt_parser.get_args from: 'samtools',         default_value: [],        comment: 'Argument for the Tool samtools sort' %>
    ~
  end

  def tool_template
    template = %~
      ## Inputs/Outputs
      #-- Inputs Templates    # .files_list take String or Array with files names or wildcard and return an Array of files
      files_list       = @datamanager.files_list( path_list: [normal_input_dir,tumor_input_dir], name_list: "\#{input_files_name}.\#{input_extension}") # find all input files
      @log.info(task_name) {" Collect inputs files \#{files_list.size} file(s) found"}
      sample_group_list= @datamanager.group_files( files_array: files_list, group_tags: [normal_tag, tumor_tag], check_group_size: true)                 # group files by N or T tags
      @log.info(task_name) {" Creating groups with *\#{normal_tag}, *\#{tumor_tag}"}
      FileUtils.mkdir_p output_dir # Create the output_dir if it doesn't exist
      ## Step1: Realigner Target Creator
      for files in sample_group_list do
        # Input/Output
        basename = files["id"]
        file_normal = files[normal_tag]
        file_tumor  = files[tumor_tag]
        now         = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        output      = "\#{output_dir}/\#{basename}\#{output_suffix}.bam"
        stdout      = "\#{output_dir}/\#{basename}\#{output_suffix}_stdout-\#{now}"
        stderr      = "\#{output_dir}/\#{basename}\#{output_suffix}_stderr-\#{now}"
        normal_count = 1
        tumor_count  = 1
        ## Run samtools on normal bam file
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "\#{samtools_bin} view"
        cmd.line << "-F 0x4"   # 0x4   UNMAP
        cmd.line << "-F 0x100" # 0x100 secondary
        cmd.line << "-F 0x400" # 0x400 duplicate
        cmd.line << "-F 0x800" # 0x800 supplementary
        cmd.line << "-@ \#{core}"
        cmd.line << "\#{file_normal}"
        cmd.line << "\#{arg_for_samtools}"
        cmd.line << "| wc -l | awk '{print $1}' "
        cmd.line << "2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        normal_count = cmd.captured_stdout  if not debug
        ## Run samtools on tumor bam file
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "\#{samtools_bin} view"
        cmd.line << "-F 0x4"   # 0x4   UNMAP
        cmd.line << "-F 0x100" # 0x100 secondary
        cmd.line << "-F 0x400" # 0x400 duplicate
        cmd.line << "-F 0x800" # 0x800 supplementary
        cmd.line << "-@ \#{core}"
        cmd.line << "\#{file_tumor}"
        cmd.line << "\#{arg_for_samtools}"
        cmd.line << "| wc -l | awk '{print $1}' "
        cmd.line << "2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        tumor_count = cmd.captured_stdout   if not debug
        ## Ratio between the two bam files
        ratio = normal_count.to_f / tumor_count.to_f
        @log.info(task_name) {"Ratio  \#{file_normal} / \#{file_tumor} = \#{ratio}"}
        ## Write Ratio
        ratio_file = "\#{output_dir}/" + basename + ".ratio"
        dest       = File.open(ratio_file, "w")
        dest.puts ratio
        dest.close
        # - Error Test -
        if File.file?(ratio_file) # if the file exist
          error_list.push "\#{ratio_file} output file is empty"  if File.size(ratio_file)  == 0 # the size should be > 0
        else
          error_list.push "\#{ratio_file} output file not found" # boolean
        end
        # - Error Test -
      end
    ~
  end

end
