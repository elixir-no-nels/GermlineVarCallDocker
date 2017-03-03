module Templates

  # get General  Configuration information
  def global_config
    template = %~
      desc "#{@description}"
      multitask :#{@task_name} #{self.add_depend_list} do |t,args|
        #-- Get instance from the Pipeline framework if the workflow is running from it
        @log         = args[:log]         if not args[:log].nil?
        @datamanager = args[:datamanager] if not args[:datamanager].nil?
        ## Gather Variables form the workflow config.yaml file
        ## All information here will be editable in the saved Rakfile step
        ##
        #-- General Informations
        workflow_id     = "#{@workflow_id}"
        task_name       = "#{@task_name}"
        descrition      = "#{@description}"
        project_path    = "#{@project_path}"
        step_status_dir = "#{@step_status_dir}"
        debug           = #{@debug}
        status_dir      = "\#{project_path}/\#{step_status_dir}"
        FileUtils.mkdir_p status_dir
        check_file      = "\#{status_dir}/check_\#{workflow_id}-\#{task_name}.passed"
        starting_time   = Time.new
        now             = starting_time.strftime("%d_%m_%Y-%H_%M_%S")
        @log.info(task_name) {"\#{descrition} START:  Start|\#{starting_time.to_i}"}
        warning_list    = []  # Store Warning messages
        error_list      = []  # Store Error   messages
    ~
  end

  # get Specific Configuration from the template defined in the herited class
  def get_config_erb
    @log.fatal 'config_template function must be define in your tool module'; exit
  end

  # to Check the if this task is already done
  def test_validation
    template = %~
      # This step is it already validated ?
      if File.exist? check_file
        @log.info(task_name) {"Checked by \#{check_file} -> Skip"}
        next
      end
    ~
  end

  # This function is re-defined in inherited Class.
  def tool_template
    @log.fatal 'tool_template function cannot be used directly'; exit
  end

  # to Check the if this task is already done
  def write_validation
    template = %~
      # check validation info.
      @log.info(task_name) {"\#{descrition} END:  Start|\#{starting_time.to_i}|  End|\#{Time.new.to_i}|  Execution time|\#{Time.new - starting_time}| seconds"}
      # Warning ?
      if not warning_list.empty?
        for message in warning_list do
          @log.warn(task_name) {"\#{descrition} : \#{message}"}
        end
      end
      # Errors ?
      if not error_list.empty?
        for message in error_list do
          @log.error(task_name) {"\#{descrition} : \#{message}"}
        end
        @log.fatal(task_name) {"\#{descrition} fail. The Workflow will stop"}; exit
      end
      # No error or warning : the step is valid
      if error_list.empty? and warning_list.empty?
        FileUtils.touch check_file
      end
    ~
  end

  def close_step
    template = %~
      end
    ~
  end

end
