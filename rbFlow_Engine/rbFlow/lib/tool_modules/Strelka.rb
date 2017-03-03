# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "Strelka"

class Strelka < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     normal_input_dir = <%= @opt_parser.get      from: 'normal_input_dir', default_value: '',    required: true,  type: String, comment: 'Input directory for Normal bam Samples' %>
     tumor_input_dir  = <%= @opt_parser.get      from: 'tumor_input_dir',  default_value: '',    required: true,  type: String, comment: 'Input directory for Tumoral bam Samples' %>
     input_files_name = <%= @opt_parser.get      from: 'input_name',      default_value: '',     required: true,  type: String, comment: 'name for input files (with sh regexp)' %>
     input_extension  = <%= @opt_parser.get      from: 'input_extension',  default_value: '',    required: true,  type: String, comment: 'Extension of inputs files without the dot separator' %>
     normal_tag       = <%= @opt_parser.get      from: 'normal_tag',       default_value: 'B',   required: true,  type: String, comment: 'extension to select input files' %>
     tumor_tag        = <%= @opt_parser.get      from: 'tumor_tag',        default_value: 'T',   required: true,  type: String, comment: 'extension to select Normal input files' %>
     output_dir       = <%= @opt_parser.get      from: 'output_dir',       default_value: 'output', required: true, type: String, comment: 'Output Directory' %>
     ref_path         = <%= @opt_parser.get      from: 'ref_path',         default_value: '',    required: true,  type: String, comment: 'Genome reference' %>
     core             = <%= @opt_parser.get      from: 'core',             default_value: 1,     required: false, type: Integer, comment: 'Number of core to use' %>
     strelka_bin      = <%= @opt_parser.get      from: 'strelka_bin',      default_value: '',    required: true,  type: String, comment: 'The Strelka binary with path' %>
     arg_strelka      = <%= @opt_parser.get_args from: 'strelka',          default_value: [],    comment: 'Argument for Strelka' %>
     # Strelka conf
     isSkipDepthFilters                 = <%= @opt_parser.get from: 'isSkipDepthFilters'                 , default_value: 0,         required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     maxInputDepth                      = <%= @opt_parser.get from: 'maxInputDepth'                      , default_value: 10000,     required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     depthFilterMultiple                = <%= @opt_parser.get from: 'depthFilterMultiple'                , default_value: 3.0,       required: false, type: Float,  comment: 'To change this parameter in the Strelka conf file' %>
     snvMaxFilteredBasecallFrac         = <%= @opt_parser.get from: 'snvMaxFilteredBasecallFrac'         , default_value: 0.4,       required: false, type: Float,  comment: 'To change this parameter in the Strelka conf file' %>
     snvMaxSpanningDeletionFrac         = <%= @opt_parser.get from: 'snvMaxSpanningDeletionFrac'         , default_value: 0.75,      required: false, type: Float,  comment: 'To change this parameter in the Strelka conf file' %>
     indelMaxWindowFilteredBasecallFrac = <%= @opt_parser.get from: 'indelMaxWindowFilteredBasecallFrac' , default_value: 0.3,       required: false, type: Float,  comment: 'To change this parameter in the Strelka conf file' %>
     indelMaxIntHpolLength              = <%= @opt_parser.get from: 'indelMaxIntHpolLength'              , default_value: 14,        required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     indelMaxRefRepeat                  = <%= @opt_parser.get from: 'indelMaxRefRepeat'                  , default_value: 8,         required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     ssnvPrior                          = <%= @opt_parser.get from: 'ssnvPrior'                          , default_value: 0.000001,  required: false, type: Float,  comment: 'To change this parameter in the Strelka conf file' %>
     sindelPrior                        = <%= @opt_parser.get from: 'sindelPrior'                        , default_value: 0.000001,  required: false, type: Float,  comment: 'To change this parameter in the Strelka conf file' %>
     ssnvNoise                          = <%= @opt_parser.get from: 'ssnvNoise'                          , default_value: 0.0000005, required: false, type: Float,  comment: 'To change this parameter in the Strelka conf file' %>
     sindelNoise                        = <%= @opt_parser.get from: 'sindelNoise'                        , default_value: 0.000001,  required: false, type: Float,  comment: 'To change this parameter in the Strelka conf file' %>
     ssnvNoiseStrandBiasFrac            = <%= @opt_parser.get from: 'ssnvNoiseStrandBiasFrac'            , default_value: 0.5,       required: false, type: Float,  comment: 'To change this parameter in the Strelka conf file' %>
     minTier1Mapq                       = <%= @opt_parser.get from: 'minTier1Mapq'                       , default_value: 20,        required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     minTier2Mapq                       = <%= @opt_parser.get from: 'minTier2Mapq'                       , default_value: 5,         required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     ssnvQuality_LowerBound             = <%= @opt_parser.get from: 'ssnvQuality_LowerBound'             , default_value: 15,        required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     sindelQuality_LowerBound           = <%= @opt_parser.get from: 'sindelQuality_LowerBound'           , default_value: 30,        required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     isWriteRealignedBam                = <%= @opt_parser.get from: 'isWriteRealignedBam'                , default_value: 0,         required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     binSize                            = <%= @opt_parser.get from: 'binSize'                            , default_value: 25000000,  required: false, type: Integer, comment: 'To change this parameter in the Strelka conf file' %>
     extraStrelkaArguments              = <%= @opt_parser.get from: 'extraStrelkaArguments'              , default_value: '',        required: false, type: String, comment: 'To change this parameter in the Strelka conf file' %>
    ~
  end

  def tool_template
    template = %~
      ## Prepare the configuration file for Strelka
      strelka_config = "[user]"
      strelka_config = strelka_config + "\\nisSkipDepthFilters =                 " + "\#{isSkipDepthFilters}"
      strelka_config = strelka_config + "\\nmaxInputDepth =                      " + "\#{maxInputDepth}"
      strelka_config = strelka_config + "\\ndepthFilterMultiple =                " + "\#{depthFilterMultiple}"                # explicit float (convert scientific notation if needed)
      strelka_config = strelka_config + "\\nsnvMaxFilteredBasecallFrac =         " + "\#{snvMaxFilteredBasecallFrac}"         # explicit float (convert scientific notation if needed)
      strelka_config = strelka_config + "\\nsnvMaxSpanningDeletionFrac =         " + "\#{snvMaxSpanningDeletionFrac}"         # explicit float (convert scientific notation if needed)
      strelka_config = strelka_config + "\\nindelMaxWindowFilteredBasecallFrac = " + "\#{indelMaxWindowFilteredBasecallFrac}" # explicit float (convert scientific notation if needed)
      strelka_config = strelka_config + "\\nindelMaxIntHpolLength =              " + "\#{indelMaxIntHpolLength}"
      strelka_config = strelka_config + "\\nindelMaxRefRepeat =                  " + "\#{indelMaxRefRepeat}"
      strelka_config = strelka_config + "\\nssnvPrior =                          " + "\#{ssnvPrior}"                          # explicit float (convert scientific notation if needed)
      strelka_config = strelka_config + "\\nsindelPrior =                        " + "\#{sindelPrior}"                        # explicit float (convert scientific notation if needed)
      strelka_config = strelka_config + "\\nssnvNoise =                          " + "\#{ssnvNoise}"                          # explicit float (convert scientific notation if needed)
      strelka_config = strelka_config + "\\nsindelNoise =                        " + "\#{sindelNoise}"                        # explicit float (convert scientific notation if needed)
      strelka_config = strelka_config + "\\nssnvNoiseStrandBiasFrac =            " + "\#{ssnvNoiseStrandBiasFrac}"            # explicit float (convert scientific notation if needed)
      strelka_config = strelka_config + "\\nminTier1Mapq =                       " + "\#{minTier1Mapq}"
      strelka_config = strelka_config + "\\nminTier2Mapq =                       " + "\#{minTier2Mapq}"
      strelka_config = strelka_config + "\\nssnvQuality_LowerBound =             " + "\#{ssnvQuality_LowerBound}"
      strelka_config = strelka_config + "\\nsindelQuality_LowerBound =           " + "\#{sindelQuality_LowerBound}"
      strelka_config = strelka_config + "\\nisWriteRealignedBam =                " + "\#{isWriteRealignedBam}"
      strelka_config = strelka_config + "\\nbinSize =                            " + "\#{binSize}"
      strelka_config = strelka_config + "\\nextraStrelkaArguments =              " + "\#{extraStrelkaArguments}"

      #-- Inputs Templates    # .files_list take String or Array with files names or wildcard and return an Array of files
      files_list       = @datamanager.files_list( path_list: [normal_input_dir,tumor_input_dir], name_list: "\#{input_files_name}.\#{input_extension}") # find all input files
      @log.info(task_name) {" Collect input files \#{files_list.size} file(s) found"}
      sample_group_list= @datamanager.group_files( files_array: files_list, group_tags: [normal_tag, tumor_tag], check_group_size: true)                 # group files by N or T tags
      @log.info(task_name) {" Creating groups with *\#{normal_tag}, *\#{tumor_tag}"}
      FileUtils.mkdir_p output_dir # Create the output_dir if it doesn't exist

      for files in sample_group_list do
        # Input/Output
        base_name = files["id"]
        file_normal = files[normal_tag]
        file_tumor  = files[tumor_tag]
        #-- Commands
        # Write the config file
        now         = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        config_file = "\#{output_dir}/config_\#{now}.cfg"
        dest        = File.open(config_file, "w")
        dest.puts strelka_config
        dest.close

        ## the Strelka Configuration and creation of the Makefile
        stdout = "\#{output_dir}/Strelka_\#{base_name}_stdout-\#{now}.log"
        stderr = "\#{output_dir}/Strelka_\#{base_name}_stderr-\#{now}.log"
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "\#{strelka_bin}"
        cmd.line << "--normal=\#{file_normal}"
        cmd.line << "--tumor=\#{file_tumor}"
        cmd.line << "--ref=\#{ref_path}"
        cmd.line << "--config=\#{config_file}"
        cmd.line << "--output-dir=\#{output_dir}/Strelka-\#{now}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        output = "\#{output_dir}/Strelka-\#{now}/Makefile"
        # - Error Test -
        if File.file?(output) # if the file exist
          error_list.push "\#{output} output file is empty"  if File.size(output)  == 0 # the size should be > 0
        else
          error_list.push "\#{output} output file not found" # boolean
        end
        # - Error Test -

        # Run Make Strelka analysis
        # cd ./myAnalysis; make -j 8
        stdout = "\#{output_dir}/Strelka_make_stdout-\#{now}.log"
        stderr = "\#{output_dir}/Strelka_make_stderr-\#{now}.log"
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cd \#{output_dir}/Strelka-\#{now} && make -j \#{core}"
        cmd.run compress_spaces: true, debug_mode: debug
      end
    ~
  end

end
