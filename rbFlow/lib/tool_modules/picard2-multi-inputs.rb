# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "Picard2MultiInput"

class Picard2MultiInput < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     input_dir         = <%= @opt_parser.get       from: 'input_dir',          default_value: '',         required: true,  type: String, comment: 'Input directory' %>
     input_files       = <%= @opt_parser.get       from: 'input_files',        default_value: '',         required: true,  type: String, comment: 'files to select as input files' %>
     output_dir        = <%= @opt_parser.get       from: 'output_dir',         default_value: 'output',   required: true,  type: String, comment: 'Output Directory' %>
     output_suffix     = <%= @opt_parser.get       from: 'output_suffix',      default_value: '',         required: false, type: String, comment: 'Suffix for the output file' %>
     group_by_samples  = <%= @opt_parser.get       from: 'group_by_samples',   default_value: '',         required: false, type: String, comment: 'If True, group files a sample names contains in the file name' %>
     group_spliter     = <%= @opt_parser.get       from: 'group_spliter',      default_value: '_',        required: false, type: String, comment: 'Define the character to use to split the sample tag from the sample name' %>
     group_on_index    = <%= @opt_parser.get       from: 'group_on_index',     default_value: 0,          required: false, type: Integer, comment: 'Position of the sample tag after spliting of the file name (start by 0)' %>
     picard2_jar       = <%= @opt_parser.get       from: 'picard2_jar',        default_value: '',         required: true,  type: String, comment: 'path/binary.jar for Picard2' %>
     picard2_command   = <%= @opt_parser.get       from: 'picard2_command',    default_value: '',         required: true,  type: String, comment: 'Picard Command' %>
     java_bin          = <%= @opt_parser.get       from: 'java_bin',           default_value: 'java',     required: false, type: String, comment: 'binary or Path/binary for java' %>
     arg_java          = <%= @opt_parser.get_args  from: 'java',               default_value: ['-Xmx4G'], comment: 'Argument send to Java' %>
     arg_for_picard2   = <%= @opt_parser.get_args  from: 'picard2',            default_value: [],         comment: 'Argument for the Tool picard2' %>

    ~
  end

  def tool_template
    template = %~
      #-- Inputs Templates
      all_inputs = @datamanager.files_list( path_list: input_dir, name_list: "\#{input_files}")
      @log.info(task_name) {" Collect input files \#{all_inputs.size} file(s) found"}
      FileUtils.mkdir_p output_dir

      #Get list of samples
      groups_list = ['*']
      if group_by_samples != ''
        @log.info(task_name) {" Regroup file by Samples, sample name on index \#{group_on_index} after spliting file names with \#{group_spliter}"}
        groups_list = []
        all_inputs.each do |file|
          filename = file.split('/')[-1] # Get the file name only
          groupname = filename.split(group_spliter)[group_on_index]
          groups_list.push groupname if not groups_list.include? groupname
        end
        @log.info(task_name) {" Group by samples: \#{groups_list.size} samples found"}
      end
      error_list.push 'Cannot find sample tags to group files' if groups_list.size == 0

      #Use this list of sample names as a filter for the loop
      ## Inputs/Outputs
      groups_list.each do |sample_tag|
        files_list = []
        if sample_tag == '*'
          files_list = all_inputs
        else
          all_inputs.each do |file|
            files_list.push file if file.include? sample_tag
          end
        end
        @log.info(task_name) {" Sample: \#{sample_tag} \#{files_list.size} files found"}

        files    = files_list.join " INPUT="
        now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        basename = "sample_\#{sample_tag}"
        output   = "\#{output_dir}/\#{basename}\#{output_suffix}.bam"
        stdout   = "\#{output_dir}/\#{basename}\#{output_suffix}_stdout-\#{now}.log"  #"
        stderr   = "\#{output_dir}/\#{basename}\#{output_suffix}_stderr-\#{now}.log"  #"
        ## the actual picard Sort Sam
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "cd \#{project_path}; \#{java_bin} \#{arg_java} "
        cmd.line << "-jar \#{picard2_jar} "
        cmd.line << "\#{picard2_command} "
        cmd.line << "INPUT=\#{files} "
        cmd.line << "\#{arg_for_picard2} "
        cmd.line << "OUTPUT=\#{output} "
        cmd.line << "> \#{stdout} 2> \#{stderr} "
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
      end
    ~
  end

end
