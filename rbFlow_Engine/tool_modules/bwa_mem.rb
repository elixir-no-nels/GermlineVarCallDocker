# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "BWA_MEM"

# The module itself
class BWA_MEM < Toolbase

  def get_config_template
    erb_template = %~
     input_dir        = <%= @opt_parser.get      from: 'input_dir',       default_value: 'input',  required: true,  type: String, comment: 'Input directory' %>
     output_dir       = <%= @opt_parser.get      from: 'output_dir',      default_value: 'output', required: true,  type: String, comment: 'Output Directory' %>
     output_suffix    = <%= @opt_parser.get      from: 'output_suffix',   default_value: 'bwa',    required: false, type: String, comment: 'suffix for output files' %>
     input_files_name = <%= @opt_parser.get      from: 'input_name',      default_value: '',       required: true,  type: String, comment: 'name for input files (with sh regexp)' %>
     input_extension  = <%= @opt_parser.get      from: 'input_extension',  default_value: '',      required: true,  type: String, comment: 'Extension of inputs files without the dot separator' %>
     input_R1_tag     = <%= @opt_parser.get      from: 'input_R1_tag',    default_value: 'R1',     required: true,  type: String, comment: 'tag to select files R1' %>
     input_R2_tag     = <%= @opt_parser.get      from: 'input_R2_tag',    default_value: 'R2',     required: true,  type: String, comment: 'tag to select files R2' %>
     bwa_index        = <%= @opt_parser.get      from: 'bwa_index',       default_value: '',       required: true,  type: String, comment: 'index file with path' %>
     read_groups      = <%= @opt_parser.get      from: 'read_groups',     default_value: ['X'],    required: true,  type: Hash,   comment: 'Read Groups informations Read Groups informations : ID,SM,LB,PL,PU' %>
     bwa_bin          = <%= @opt_parser.get      from: 'bwa_bin',         default_value: 'bwa',    required: false, type: String, comment: 'binary or Path/binary for bwa' %>
     core             = <%= @opt_parser.get      from: 'core',            default_value: 1,        required: false, type: Fixnum, comment: 'Number of core to use' %>
     arg_for_bwa      = <%= @opt_parser.get_args from: 'bwa',             default_value: [],       comment: 'Argument send to BWA' %>
    ~
  end

  ## Template for the Rake Task
  def tool_template()
    @step = %~
    # Taking inputs Files
    files_list       = @datamanager.files_list( path_list: input_dir, name_list: "\#{input_files_name}.\#{input_extension}")          # find all input files
    @log.info(task_name) {" Collect input files \#{files_list.size} file(s) found"}
    paired_files_list= @datamanager.group_files( files_array: files_list, group_tags: [input_R1_tag, input_R2_tag], check_group_size: true) # group files by R or F tags
    @log.info(task_name) {" Creating groups with *\#{input_R1_tag}, *\#{input_R2_tag}"}
    FileUtils.mkdir_p output_dir

    ## Start main loop on inputs files
    for files in paired_files_list do
      ## Inputs/Outputs
      file_R1  = files[input_R1_tag]
      file_R2  = files[input_R2_tag]
      basename = files['id']
      now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
      output   = "\#{output_dir}/\#{basename}\#{output_suffix}.sam"
      stderr   = "\#{output_dir}/\#{basename}\#{output_suffix}_stderr-\#{now}.log"
      # ------------------ ReadGroup ------------------
      # Build read_groups from the input basename
      # tag can be 'ID','SM','LB','PL','PU'
      # each tag can be skipped, or can take String, or can take an Integer or Array string and Integer and if a split caracter is given
      # The split caracter contain is used to split the basename of the input file
      # and Integer or Array of integer are the index of the element used to build the content of the tag
      # Yaml config arg example for readgroups
      # ------- Sample
      # read_groups:
      #   split: "_"       # Split the input file name with '_'
      #   ID: [1,2,"N"]    # use use the index 1 and 2 of the splited file name and "N" string ID="index1_index2_N"
      #   SM: 0            # use the index 0 of the splited file name
      #   LB: "RH"         # use "RH" string
      #   PL: "ILLUMINA"   # use "Illumina" string
      # -------
      readgroup_string = ''  # the ReadGroup final string
      if read_groups != false
        rg = {}  # used to store each tag of the ReadGroup
        for tag in ['ID','SM','LB','PL','PU'] do
          rg[tag] = 'NotDefined'
          if (read_groups[tag].class == Fixnum or read_groups[tag].class == Array) and read_groups['split'].class == String
            splited_name = basename.split read_groups['split']
            rg[tag] = splited_name[read_groups[tag]] if read_groups[tag].class == Fixnum
            if read_groups[tag].class == Array
              rg[tag] = ''
              for element in read_groups[tag]
                rg[tag] = rg[tag] + '_' + splited_name[element] if element.class == Fixnum
                rg[tag] = rg[tag] + '_' + element               if element.class == String
              end
            end
          else
            rg[tag] = read_groups[tag] if read_groups[tag].class == String
          end
        end
        readgroups_string =  ' -R "@RG\\t'
        readgroups_string << "ID:\#{rg["ID"]}"
        readgroups_string << '\\t'
        readgroups_string << "SM:\#{rg["SM"]}"
        readgroups_string << '\\t'
        readgroups_string << "LB:\#{rg["LB"]}"
        readgroups_string << '\\t'
        readgroups_string << "PL:\#{rg["PL"]}"
        readgroups_string << '\\t'
        readgroups_string << "PU:\#{rg["PU"]}"
        readgroups_string << '" '
      end
      # ------------------ ReadGroup ------------------
      ## the actual mapping
      cmd = Command.new task_name: task_name, log: @log
      cmd.line << "\#{bwa_bin} mem"
      cmd.line << "-t \#{core}"
      cmd.line << "\#{readgroups_string}"
      cmd.line << "\#{arg_for_bwa}"
      cmd.line << "\#{bwa_index}"
      cmd.line << "\#{file_R1}"
      cmd.line << "\#{file_R2}"
      cmd.line << ">  \#{output} 2> \#{stderr}"
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
