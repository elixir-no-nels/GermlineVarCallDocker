
      desc "Test task 2 normal"
      multitask :test2_normal => [ :test1a_docker, :test1b_docker ]  do |t,args|
        #-- Get instance from the Pipeline framework if the workflow is running from it
        @log         = args[:log]         if not args[:log].nil?
        @datamanager = args[:datamanager] if not args[:datamanager].nil?
        ## Gather Variables form the workflow config.yaml file
        ## All information here will be editable in the saved Rakfile step
        ##
        #-- General Informations
        workflow_id     = "workflow_test_docker"
        task_name       = "test2_normal"
        descrition      = "Test task 2 normal"
        project_path    = "/Users/Ghis/Work/Depot-Perso/rbFlow/ProjectTest/"
        debug           = false
        status_dir      = "#{project_path}/step_status"
        FileUtils.mkdir_p status_dir
        check_file      = "#{status_dir}/check_#{workflow_id}-#{task_name}.passed"
        starting_time   = Time.new
        now             = starting_time.strftime("%d_%m_%Y-%H_%M_%S")
        @log.info(task_name) {"#{descrition} START:  Start|#{starting_time.to_i}"}
        warning_list    = []  # Store Warning messages
        error_list      = []  # Store Error   messages
    
     docker_images = "alpine"
     docker_opts   = " --rm "
     wait_time     = 2
     arg_for_tool  = ""
    
      # This step is it already validated ?
      if File.exist? check_file
        @log.info(task_name) {"Checked by #{check_file} -> Skip"}
        next
      end
    

      #-- Commands

      # Hello from a container
      cmd = Command.new task_name: task_name, log: @log
      cmd.line << "echo hello from a container && sleep #{wait_time} #{arg_for_tool}"
      cmd.run compress_spaces: true, debug_mode: debug, docker_id: docker_images, docker_options: docker_opts
    
      # check validation info.
      @log.info(task_name) {"#{descrition} END:  Start|#{starting_time.to_i}|  End|#{Time.new.to_i}|  Execution time|#{Time.new - starting_time}| seconds"}
      # Warning ?
      if not warning_list.empty?
        for message in warning_list do
          @log.warn(task_name) {"#{descrition} : #{message}"}
        end
      end
      # Errors ?
      if not error_list.empty?
        for message in error_list do
          @log.error(task_name) {"#{descrition} : #{message}"}
        end
        @log.fatal(task_name) {"#{descrition} fail. The Workflow will stop"}; exit
      end
      # No error or warning : the step is valid
      if error_list.empty? and warning_list.empty?
        FileUtils.touch check_file
      end
    
      end
    
