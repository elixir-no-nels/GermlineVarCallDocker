# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "Delly1"

class Delly1 < Toolbase

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
     output_suffix    = <%= @opt_parser.get      from: 'output_suffix',    default_value: '_delly', required: false, type: String, comment: 'suffix for output files' %>
     analysis_types   = <%= @opt_parser.get      from: 'analysis_types',   default_value: ["DEL","DUP","INV","TRA"], required: false, type: Array, comment: 'Analisys to run : ["DEL","DUP","INV","TRA"]' %>
     delly_bin        = <%= @opt_parser.get      from: 'delly_bin',        default_value: '',        required: true,  type: String, comment: 'binary or Path/binary for delly' %>
     delly_sf_script  = <%= @opt_parser.get      from: 'delly_sf_script',  default_value: '',        required: true,  type: String, comment: 'Path/binary for delly_sf.py' %>
     ref_path         = <%= @opt_parser.get      from: 'ref_path',         default_value: '',        required: true,  type: String, comment: 'Genome reference (Fasta file with index)' %>
     exclude_regions  = <%= @opt_parser.get      from: 'exclude_regions',  default_value: '',        required: true,  type: String, comment: 'Exlude list (Fasta file with index)' %>
     core             = <%= @opt_parser.get      from: 'core',             default_value: 1,         required: false, type: Fixnum, comment: 'Number of core to use' %>
     arg_for_delly    = <%= @opt_parser.get_args from: 'delly',            default_value: [],        comment: 'Argument for delly' %>
     arg_for_delly_sf = <%= @opt_parser.get_args from: 'delly_somaticfilter', default_value: [ "-a 0.05", "-m 50" ], comment: 'Argument for delly somaticfilter' %>
    ~
  end

  def tool_template
    template = %~
      ## Inputs/Outputs
      #-- Inputs Templates    # .files_list take String or Array with files names or wildcard and return an Array of files
      files_list       = @datamanager.files_list( path_list: [normal_input_dir,tumor_input_dir], name_list: "\#{input_files_name}.\#{input_extension}") # find all input files
      @log.info(task_name) {" Collect input files \#{files_list.size} file(s) found"}
      sample_group_list= @datamanager.group_files( files_array: files_list, group_tags: [normal_tag, tumor_tag], check_group_size: true)                 # group files by N or T tags
      @log.info(task_name) {" Creating groups with *\#{normal_tag}, *\#{tumor_tag}"}
      FileUtils.mkdir_p output_dir # Create the output_dir if it doesn't exist
      exclude_regions = '-x ' + exclude_regions if exclude_regions != ''
      for files in sample_group_list do
        base_name = files["id"]
        # input files name
        inputN = files[normal_tag]
        inputT = files[tumor_tag]
        for analysis_type in analysis_types
          # index input, replace extention bam by bai
          inputN_idx = inputN.gsub ".bam", ".bai" # replace bam by bai to have the bam index original file name
          inputT_idx = inputT.gsub ".bam", ".bai" # replace bam by bai to have the bam index original file name
          # For correct somatic filter function, the tumor sample needs string "[Tt]umor" in its name, the control needs string "[Nn]ormal"
          # DELLY requires BAM index files with names *bam.bai
          # files base name names (no path and no ext)
          inputN_basename = File.basename(inputN, ".*")
          inputT_basename = File.basename(inputT, ".*")
          # add pathes to names, output is used to avoid to add bam files in another directory
          link_N         = output_dir + "/" + inputN_basename + "_" + analysis_type + "_Normal_delly.bam"
          link_T         = output_dir + "/" + inputT_basename + "_" + analysis_type + "_Tumor_delly.bam"
          link_N_idx     = output_dir + "/" + inputN_basename + "_" + analysis_type + "_Normal_delly.bam.bai"
          link_T_idx     = output_dir + "/" + inputT_basename + "_" + analysis_type + "_Tumor_delly.bam.bai"
          # create input for bam
          FileUtils.cp inputN, link_N
          FileUtils.cp inputT, link_T
          # create input for bam.index
          FileUtils.cp inputN_idx, link_N_idx
          FileUtils.cp inputT_idx, link_T_idx
          #################################
          delly_ouput  = "\#{output_dir}/\#{base_name}_delly_\#{analysis_type}.vcf"
          now          = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
          stdout       = "\#{output_dir}/\#{base_name}_delly_stdout-\#{now}"
          stderr       = "\#{output_dir}/\#{base_name}_delly_stderr-\#{now}"
          ## the actual delly sort
          cmd = Command.new task_name: task_name, log: @log
          cmd.line << "export OMP_NUM_THREADS=\#{core};"
          cmd.line << "\#{delly_bin}"
          cmd.line << "\#{exclude_regions}"
          cmd.line << "-t \#{analysis_type}"
          cmd.line << "-g \#{ref_path}"
          cmd.line << "\#{arg_for_delly}"
          cmd.line << "-o \#{delly_ouput}"
          cmd.line << "\#{link_N}"
          cmd.line << "\#{link_T}"
          cmd.line << "> \#{stdout} 2> \#{stderr}"
          cmd.run compress_spaces: true, debug_mode: debug
          # - Error Test -
          if File.file?(delly_ouput) # if the file exist
            error_list.push "\#{delly_ouput} output file is empty" if File.size(delly_ouput) == 0 # the size should be > 0
          else
            error_list.push "\#{delly_ouput} output file not found" # true
          end
          # - Error Test -
          ## delly_SomaticFiltration_default
          basename   = File.basename(delly_ouput)                              # take basename
          output_sfd = "\#{output_dir}/\#{base_name}_delly_somaticfilter_default.vcf"
          now        = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
          stdout     = "\#{output_dir}/\#{basename}_delly_somaticfilter_default_stdout-\#{now}"
          stderr     = "\#{output_dir}/\#{basename}_delly_somaticfilter_default_stderr-\#{now}"
          cmd = Command.new task_name: task_name, log: @log
          cmd.line << "python \#{delly_sf_script}"
          cmd.line << "-v \#{delly_ouput}"
          cmd.line << "-o \#{output_sfd}"
          cmd.line << "-t \#{analysis_type}"
          cmd.line << "-f"
          cmd.line << "> \#{stdout} 2> \#{stderr}"
          cmd.run compress_spaces: true, debug_mode: debug
          # - Error Test -
          if File.file?(output_sfd) # if the file exist
            error_list.push "\#{output_sfd} output file is empty" if File.size(output_sfd) == 0 # the size should be > 0
          else
            error_list.push "\#{output_sfd} output file not found" # boolean
          end
          # - Error Test -
          ## delly_SomaticFiltration_sensitive
          basename   = File.basename(delly_ouput)                              # take basename
          output_sfs = "\#{output_dir}/\#{base_name}_delly_somatic_filter_sensitive.vcf"
          now        = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
          stdout     = "\#{output_dir}/\#{basename}_delly_somaticfilter_sensitive_stdout-\#{now}"
          stderr     = "\#{output_dir}/\#{basename}_delly_somaticfilter_sensitive_stderr-\#{now}"
          cmd = Command.new task_name: task_name, log: @log
          cmd.line << "python \#{delly_sf_script}"
          cmd.line << "-v \#{delly_ouput}"
          cmd.line << "-o \#{output_sfs}"
          cmd.line << "-t \#{analysis_type}"
          cmd.line << "-f"
          cmd.line << "\#{arg_for_delly_sf}"
          cmd.line << "> \#{stdout} 2> \#{stderr}"
          cmd.run compress_spaces: true, debug_mode: debug
          # - Error Test -
          if File.file?(output_sfs) # if the file exist
            error_list.push "\#{output_sfs} output file is empty" if File.size(output_sfs) == 0 # the size should be > 0
          else
            error_list.push "\#{output_sfs} output file not found" # boolean
          end
          # - Error Test -
        end
      end
    ~
  end

end
