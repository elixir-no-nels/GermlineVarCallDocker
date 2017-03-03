# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "DefaultTaskStandAlone"

# The Tool Module itself
# inherit from Toolbase




class DefaultTaskStandAlone < Toolbase

  # Template for the Rake Task
  def step_template()
    @step = %~

      # load some usefull Classes
      puts "\n\nLoading Libs from #{@libdir}"
      puts "-------------------------------------------------------------"
      libs = "#{@libdir}/*.rb"
      Dir.chdir(File.dirname(__FILE__)){
        Dir[libs].each { |f|
          puts "include Task from " + f
          require_relative f
        }
      }
      puts "-------------------------------------------------------------\\n\\n"

      # Load all others Tasks
      puts "\\n\\nLoading Tasks"
      puts '-------------------------------------------------------------'
      Dir.chdir(File.dirname(__FILE__)){
        Dir["#{@workflow_id}_task_*.rb"].each { |f|
          puts "include Task from " + f
          require_relative f
        }
      }
      puts "-------------------------------------------------------------\\n\\n"


      # load some std Ruby libraries
      require 'rake'
      require 'fileutils'
      def create_log id: '', log_dir: '', color: true
        FileUtils.mkdir_p log_dir
        header_name      = 'rbFlow'
        extension        = 'log'
        now              = Time.new.strftime("%d_%m_%Y-%H_%M_%S")
        log_file_name    = File.expand_path("\#{log_dir}/\#{header_name}_#{@workflow_id}_\#{now}.\#{extension}")
        log_file         = File.open(log_file_name,  'a')
        logger           = Logger_ext.new MultiDelegator.delegate(:write, :close).to(STDOUT, log_file)
        logger.level     = Logger::DEBUG
        logger.progname  = id
        logger.log_dir   = log_dir
        logger.datetime_format = '%d/%m/%Y\t%H:%M:%S'
        logger.formatter = proc do |severity, datetime, progname, msg|
          if color == true
            severity = severity.green     if severity == 'INFO'
            severity = severity.yellow    if severity == 'WARN'
            severity = severity.red       if severity == 'ERROR'
            severity = severity.red.bold  if severity == 'FATAL'
            severity = severity.magenta   if severity == 'DEBUG'
            severity = severity.blue.bold if severity == 'EXECUTE'
            severity = severity.blue      if severity == 'FINISH'
            progname = progname.bold
          end
          message  = ''
          message << "\#{Time.new.to_i - @start_time}\\t"
          message << "\#{datetime}\\t"
          message << "\#{progname}\\t"
          message << "\#{severity}\\t"
          message << "\#{msg}\\n"
          message
        end
        logger
      end

      @start_time  = Time.new.to_i          # Time 0 is fix here
      @log         = create_log id: "#{@workflow_id}", log_dir: "#{@log.log_dir}" # Create The Log
      @datamanager = FileManager.new log: @log


      # The Default Task
      desc 'Default Task, Starting point of the Workflow'
      multitask :default #{self.add_depend_list} do |t,args|
        @log.info 'The Workflow is now finish'
        #sleep 1
      end
    ~
  end

end
