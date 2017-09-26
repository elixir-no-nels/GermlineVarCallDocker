require 'open3'

# Class used to build and run an external process with log
class Command

  attr_accessor :line
  attr_reader   :captured_stdout, :captured_stderr, :pid, :exit_status

  def initialize(task_name: '', log: '')
    @log             = log
    @line            = []
    @task_name       = task_name
    @pid             = false # pid of the started process.
    @exit_status     = false
    @captured_stdout = ''
    @captured_stderr = ''
  end

  def run(compress_spaces: true, debug_mode: false, docker_id: false, docker_options: false)
    self.build!
    self.compress_spaces! if compress_spaces
    self.dockerize(docker_id: docker_id, docker_options: docker_options) if docker_id
    @log.execute(@task_name) { @line }
    if not debug_mode # debug mode
      Open3.popen3(@line) do |stdin, stdout, stderr, wait_thr|
        @pid             = wait_thr.pid
        @captured_stdout = stdout.read
        @captured_stderr = stderr.read
        @exit_status     = wait_thr.value
        unless exit_status.success?
          @log.warn(@task_name) { ": exit with error level" }
        end
      end
      @log.finish(@task_name) { @line }
    else
      wait_time = 0.2
      @log.debug(@task_name) { "Tool run in Debug mode : Skip the execution and wait #{wait_time} second(s) !!!" }
      sleep wait_time
    end
  end

  def dockerize(docker_id: false, docker_options: false)
    @log.info(@task_name) { "using docker images : #{docker_id}" }
    @line = "docker run -u=#{self.get_uid}:#{self.get_gid} #{docker_options} #{docker_id} sh -c \"#{@line}\""
  end

  def test_binary
    out = `wich #{@line}` # test
    if out.include? 'not found'
      @log.warn(@task_name) { "#{@line} not found" }
    end
  end

  # command line Array to String
  def build!
    @line = @line.join ' ' if @line.class == Array
  end

  # remove multiple spaces
  def compress_spaces!
    @line.gsub!(/\s+/, ' ')
  end

  def get_uid
    return `id -u`.chomp!
  end

  def get_gid
    return `id -g`.chomp!
  end

end
