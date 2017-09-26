# Class to manage files inputs
# Can load File/Files list with or without wildcards characters
# Can Can give files by pairs or groups
class FileManager
  def initialize(log: '', options: '')
    @options = options
    @log     = log
    # @log.info message: "INIT DataFileManager"
  end

  # Take path(es) and file(s) to search all files matching.
  # Arg : path_list take a String or an Array of string locations used to search files
  # Arg : name_list take a String or an Array of string containing files names, wildcard are accepted.
  # return : all files found in an Array  ['fileA.fastq','fileB.fastq','fileC.fastq']
  def files_list(path_list: '', name_list: '')
    # Check
    path_list  = [path_list] if path_list.class == String  # transform String in Array
    name_list  = [name_list] if name_list.class == String  # transform String in Array
    path_list.uniq! # Remove duplicate
    name_list.uniq! # Remove duplicate
    (@log.fatal {'FileManager.files_list() : no path given'}; exit )      if :path_list.size == 0
    (@log.fatal {'FileManager.files_list() : no file list given'}; exit ) if :name_list.size == 0
    # Init
    file_array = []
    # Create the list
    for path in path_list
      for file in name_list
        files      = Dir.glob(path + '/' + file)
        file_array = file_array + files
        @log.info {" FileManager search for \"#{path}/#{file}\" => found : #{Dir.glob(path + '/' + file).size} file(s)"}
      end
    end
    # Something wrong ?
    if file_array.size == 0
      @log.fatal {"FileManager : no Input Files found by files_list().path_list : #{path_list.to_s}  name_list #{name_list.to_s}"}; exit
    else
      return file_array
    end
  end

  # From a files list create groups of files with same name, differing only by the group_tag in the name
  # Arg    : files_array contain a list of files to group (output of files_list() is usable here)
  # Arg    : group_tags is a list used to form groups. A group is files with same basename after removing the tag
  # Arg    : if check_group_size is true the function raise an error if a file with each tag is not found
  # Result : return all files found in an Array (file_basename_untaged) of hash (by tags)
  #
  # if check_group_size is true the function test if all group are with a same size
  #
  # Example:
  #  file list:
  #   fileA_r1.fastq, fileA_r2.fastq, fileB_r1.fastq, fileB_r2.fastq
  # group_tag
  #  ['_r1', '_r2']
  # Result:
  #  [ {'id' => 'fileA', '_r1' => 'fileA_r1.fastq', '_r2' => 'fileA_r2.fastq'},  {'id' => 'fileb', '_r1' => 'fileB_r1.fastq', '_r2' => 'fileB_r2.fastq'} ]
  def group_files(files_array: [], group_tags: [], check_group_size: false)
    # Check
    files_array  = [files_array] if files_array.class == String  # transform String in Array
    group_tags   = [group_tags]  if group_tags.class  == String  # transform String in Array
    group_tags.uniq!  # Remove duplicate
    files_array.uniq! # Remove duplicate
    (@log.fatal {'FileManager.paired_file_list() : files_array should be > 2 #{files_array}'}; exit ) if files_array.size < 2
    (@log.fatal {'FileManager.paired_file_list() : group_tags should be  > 2 #{group_tags}'}; exit )  if group_tags.size  < 2
    # Init
    file_hash_grouped_tmp = {}  # Hash of Hash: store by file basename without tag and by tag
    file_array_grouped    = []  # Store the final result
    # Create groups of files based on untaged name and group tag
    for file_ref in files_array
      file_base_name = File.basename(file_ref, '.*')
      for tag in group_tags
        if file_base_name.include? tag
          file_base_name_untaged = file_base_name.gsub tag, ''              # Base name without the tag used as id for a group of files
          file_hash_grouped_tmp[file_base_name_untaged] = { 'id' => file_base_name_untaged } if not file_hash_grouped_tmp.key? file_base_name_untaged # create an new entry if needed
          file_hash_grouped_tmp[file_base_name_untaged].store tag, file_ref # add the element in the correct group and tag identifier
        end
      end
    end
    # Create the final result
    file_hash_grouped_tmp.each_key do |key|
      file_array_grouped.push file_hash_grouped_tmp[key]
      if check_group_size and group_tags.size != file_hash_grouped_tmp[key].size - 1 # -1 because we have the "id" tag
        @log.error "FileManager : incorect group size in paired_file_list(): wait for #{group_tags.size}, found #{file_hash_grouped_tmp[key].size - 1 }."
        @log.fatal {" hash: #{file_hash_grouped_tmp}\n key: #{key}"}; exit
      end
    end
    # Something wrong ?
    if file_array_grouped.size == 0
      @log.fatal {"FileManager : Input Files Not found by paired_file_list(). files: #{files_array.to_s} groups: #{group_tags.to_s}"}; exit
    else
      return file_array_grouped
    end
  end
end

