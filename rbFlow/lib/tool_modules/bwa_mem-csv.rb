# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "BWA_MEM_CSV"

# The module itself
class BWA_MEM_CSV < Toolbase

  def get_config_template
    erb_template = %~
     input_csv        = <%= @opt_parser.get      from: 'input_csv',       default_value: 'input',  required: true,  type: String, comment: 'Input csv file, containing the list of input files' %>
     output_dir       = <%= @opt_parser.get      from: 'output_dir',      default_value: 'output', required: true,  type: String, comment: 'Output Directory' %>
     output_suffix    = <%= @opt_parser.get      from: 'output_suffix',   default_value: 'bwa',    required: false, type: String, comment: 'suffix for output files' %>
     bwa_index        = <%= @opt_parser.get      from: 'bwa_index',       default_value: '',       required: true,  type: String, comment: 'index file with path' %>
     bwa_bin          = <%= @opt_parser.get      from: 'bwa_bin',         default_value: 'bwa',    required: false, type: String, comment: 'binary or Path/binary for bwa' %>
     core             = <%= @opt_parser.get      from: 'core',            default_value: 1,        required: false, type: Integer, comment: 'Number of core to use' %>
     arg_for_bwa      = <%= @opt_parser.get_args from: 'bwa',             default_value: [],       comment: 'Argument send to BWA' %>
    ~
  end

  ## Template for the Rake Task
  def tool_template()
    @step = %~
    FileUtils.mkdir_p output_dir
    ## Parse the CSV
    split_char = "\\t"
    File.open(input_csv, "r") do |f|
      f.each do |line|
        ## Start main loop on each line
        line.chomp!
        # Some checks
        # check the number of columns
        line_size      = line.split(split_char).size
        expected_field = 6
        if line_size != expected_field
          @log.info(task_name) {" Error on \#{input_csv} parsing"}
          @log.info(task_name) {" a line contain \#{line_size} field, \#{expected_field} are expected :"}
          @log.info(task_name) {" \#{line}"}
          exit()
        end
        # Check if there is non allowed characters (no spaces,quotes or backslash)
        if not line.match(/[\\"\\']/).nil?
          @log.info(task_name) {" Error on \#{input_csv} parsing"}
          @log.info(task_name) {" a line contain a non allowed symbol (space, tab, quote, backslash) :"}
          @log.info(task_name) {" \#{line}"}
          exit()
        end
        # Build ReadGroups
        # FLOWCELL_ID,RGSM,RGLB,Lane,File_R1,File_R2
        # RGID : the read group ID, must be unique flowcell_barcode.lane is a good ID
        # RGSM : the sample, to identify a sample splited on several files/sequencing Run
        # RGLB : Library ID, used for mark/remove duplicate.
        # RGPU : {flowcell_barcode}.{lane}.{sample_barcode}
        flowcell_id, sample, library_id, lane, file_name_R1, file_name_R2 = line.split split_char
        rgid = flowcell_id + '.' + lane
        rgpu = flowcell_id + '.' + lane + '.' + sample
        rgsm = sample
        rglb = library_id
        readgroup_string = "-R \\"@RG\\\\tID:\#{rgid}\\\\tSM:\#{rgsm}\\\\tLB:\#{rglb}\\\\tPL:ILLUMINA\\\\tPU:\#{rgpu}\\""
        ## Inputs/Outputs
        basename = sample + '_' + lane + '_' + flowcell_id
        now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        output   = "\#{output_dir}/\#{basename}\#{output_suffix}.sam"
        stderr   = "\#{output_dir}/\#{basename}\#{output_suffix}_stderr-\#{now}.log"
        ## the actual mapping
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "\#{bwa_bin} mem"
        cmd.line << "-t \#{core}"
        cmd.line << readgroup_string
        cmd.line << "\#{arg_for_bwa}"
        cmd.line << "\#{bwa_index}"
        cmd.line << "/Workflow/input/\#{file_name_R1}"
        cmd.line << "/Workflow/input/\#{file_name_R2}"
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
    end
    ~
  end

end
