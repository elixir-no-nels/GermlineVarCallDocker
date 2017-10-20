# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "GPG_encrypt"

class GPG_encrypt < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     to_ecrypt        = <%= @opt_parser.get      from: 'to_ecrypt',    default_value: '',        required: true, type:  String, comment: 'Input directory or file(s)' %>
     output_dir       = <%= @opt_parser.get      from: 'output_dir',   default_value: 'output',  required: true, type:  String, comment: 'Output Directory' %>
     output_suffix    = <%= @opt_parser.get      from: 'output_suffix',default_value: '_gpg2',   required: false, type: String, comment: 'Suffix for the output file' %>
     compress         = <%= @opt_parser.get      from: 'compress',     default_value: 'false',   required: false, type: String, comment: 'use gzip compression' %>
     pasword_file     = <%= @opt_parser.get      from: 'pasword_file', default_value:  '',       required: true, type:  String, comment: 'file containing the password' %>
     arg_for_gpg      = <%= @opt_parser.get_args from: 'gpg',          default_value: [],        comment: 'Argument for the Tool gpg' %>
    ~
  end

  def tool_template
    template = %~
      #-- Inputs Templates                                   # .files_list take String or Array with files names or wildcard and return an Array of files
      if File.directory?(to_ecrypt)
        files_list = [ to_ecrypt.split('/').compact[-1] ] # get the name of the last directory of this path
      else
        files_list = @datamanager.files_list( path_list: input_dir, name_list: "\#{input_files}")          # find all input files
        @log.info(task_name) {" Collect input files \#{files_list.size} file(s) found"}
      end
      tar_files = []
      FileUtils.mkdir_p output_dir                           # Create the output_dir if it doesn't exist
      ## Tar
      for file in files_list
        now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        basename = to_ecrypt.split('/').compact[-1] # get the name of the last name in the path
        output   = "\#{output_dir}/\#{basename}\#{output_suffix}.tar"
        output   = output + ".gz" if compress == true
        stdout   = "\#{output_dir}/\#{basename}\#{output_suffix}_tar_stdout-\#{now}"
        stderr   = "\#{output_dir}/\#{basename}\#{output_suffix}_tar_stderr-\#{now}"
        ## the actual samtools sort
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "tar"
        cmd.line << "cvpf"
        cmd.line << "z"           if compress == true
        cmd.line << "\#{output}"
        cmd.line << "\#{file}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        tar_files.push output
      end
      ## GPG
      for file in tar_files
        now      = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        basename = File.basename(file, ".*")
        output   = "\#{file}.gpg"
        stdout   = "\#{file}_gpg_stdout-\#{now}"
        stderr   = "\#{file}_gpg_stderr-\#{now}"
        ## the actual samtools sort
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "gpg2"
        cmd.line << "--batch"
        cmd.line << "--passphrase-file \#{pasword_file}"
        cmd.line << "-c"
        cmd.line << "--cipher-algo aes256"
        cmd.line << "\#{arg_for_gpg}"
        cmd.line << "-o \#{output}"
        cmd.line << "\#{file}"
        cmd.line << "> \#{stdout} 2> \#{stderr}"
        cmd.run compress_spaces: true, debug_mode: debug
        @log.info(task_name) {"Decrypt with : gpg2 --batch --passphrase-file \#{pasword_file} -d \#{output} | tar xv\#{"z" if compress == true }f -"}
        # - Error Test -
        if File.file?(output) # if the file exist
          error_list.push "\#{output} output file is empty"  if File.size(output)  == 0 # the size should be > 0
        else
          error_list.push "\#{output} output file not found" # boolean
        end
        # - Error Test -
        ## Cleaning
        cmd = Command.new task_name: task_name, log: @log
        cmd.line << "rm \#{file}"
        cmd.run compress_spaces: true, debug_mode: debug
      end
    ~
  end

end



######
#
#  # For a script compatible usage
#  # you have to provide the password from a file insted of using an interactive shell input
#  # Option are
#  # --passphrase-file passphrase.txt
#  # --batch
#
#
#
#  # Exemple: Encrypt with GnuPG2 (AES256 is a very strong symetric encryptation algorithm):
#  gpg2 --batch --passphrase-file passphrase.txt -c --cipher-algo aes256 -o secure.tar.gz.gpg  a_file_to_encrypt.txt
#
#  # Decrypt and uncompress on the fly
#  gpg2 --batch --passphrase-file passphrase.txt -d secure.tar.gz.gpg > a_file_to_encrypt.txt
#
#
#
#
#  # Exemple: Encapsulate several files with tar without compression and Encrypt on the fly with GnuPG2:
#  tar cvpf - files_to_archive_and_crypt/ | gpg2 --batch --passphrase-file passphrase.txt -c --cipher-algo aes256 -o secure.tar.gz.gpg
#
#  # Decrypt and untar on the fly
#  gpg2 --batch --passphrase-file passphrase.txt -d secure.tar.gz.gpg | tar xvf -
#
#
#
#
#  # Exemple: Encapsulate several files with tar with compression and Encrypt on the fly with GnuPG2:
#  tar czvpf - files_to_archive_and_crypt/ | gpg2 --batch --passphrase-file passphrase.txt -c --cipher-algo aes256 -o secure.tar.gz.gpg
#
#  # Decrypt and uncompress on the fly
#  gpg2 --batch --passphrase-file passphrase.txt -d secure.tar.gz.gpg | tar xzvf -

