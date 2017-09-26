# Extent String class to have a basic color managment
# Usage:
# puts "I'm back green".bg_green
# puts "I'm red and back cyan".red.bg_cyan
# puts "I'm bold and green and backround red".bold.green.bg_red
class String
  def black;          "\033[30m#{self}\033[0m" end
  def red;            "\033[31m#{self}\033[0m" end
  def green;          "\033[32m#{self}\033[0m" end
  def yellow;         "\033[33m#{self}\033[0m" end
  def blue;           "\033[34m#{self}\033[0m" end
  def magenta;        "\033[35m#{self}\033[0m" end
  def cyan;           "\033[36m#{self}\033[0m" end
  def gray;           "\033[37m#{self}\033[0m" end
  def bg_black;       "\033[40m#{self}\033[0m" end
  def bg_red;         "\033[41m#{self}\033[0m" end
  def bg_green;       "\033[42m#{self}\033[0m" end
  def bg_yellow;      "\033[43m#{self}\033[0m" end
  def bg_blue;        "\033[44m#{self}\033[0m" end
  def bg_magenta;     "\033[45m#{self}\033[0m" end
  def bg_cyan;        "\033[46m#{self}\033[0m" end
  def bg_gray;        "\033[47m#{self}\033[0m" end
  def bold;           "\033[1m#{self}\033[22m" end
  def reverse_color;  "\033[7m#{self}\033[27m" end
end

# Extend Logger class with new custom levels
require 'logger'

class Logger_ext < Logger

  attr_accessor :log_dir

  # Logging severity.
  module Severity
    # Low-level information, mostly for developers.
    DEBUG = 0
    # Generic (useful) information about system operation.
    INFO = 1
    # A warning.
    WARN = 2
    # A handleable error condition.
    ERROR = 3
    # An unhandleable error that results in a program crash.
    FATAL = 4
    # start a sub process
    EXECUTE = 5
    # finish a subprocess
    FINISH  = 6
    # An unknown message that should always be logged.
    UNKNOWN = 7

  end
  include Severity

  def level=(severity)
    if severity.is_a?(Integer)
      @level = severity
    else
      case severity.to_s.downcase
      when 'debug'.freeze
        @level = DEBUG
      when 'info'.freeze
        @level = INFO
      when 'warn'.freeze
        @level = WARN
      when 'error'.freeze
        @level = ERROR
      when 'fatal'.freeze
        @level = FATAL
      when 'execute'.freeze
        @level = EXECUTE
      when 'finish'.freeze
        @level = FINISH
      when 'unknown'.freeze
        @level = UNKNOWN
      else
        raise ArgumentError, "invalid log level: #{severity}"
      end
    end
  end

  def execute?; @level <= EXECUTE; end
  def finish?;  @level <= FINISH; end

  def execute(progname = nil, &block)
    add(EXECUTE, nil, progname, &block)
  end

  def finish(progname = nil, &block)
    add(FINISH, nil, progname, &block)
  end


  # Severity label for logging (max 5 chars).
  # Severity label for logging (max 5 chars).
  SEV_LABEL = %w(DEBUG INFO WARN ERROR FATAL EXECUTE FINISH ANY).each(&:freeze).freeze

  def format_severity(severity)
    SEV_LABEL[severity] || 'ANY'
  end

end


class MultiDelegator

  def initialize(*targets)
    @targets = targets
  end

  def self.delegate(*methods)
    methods.each do |m|
      define_method(m) do |*args|
        @targets.map { |t| t.send(m, *args) }
      end
    end
    self
  end

  class <<self
    alias to new
  end

end


############
#
#  # Test #
#
############
# def create_log
#   #log_file         = File.open('/Users/ghis/Desktop/foo.log',  'a')
#   logger = Logger_ext.new(STDOUT)
#   #logger           = Logger.new(STDOUT, File::WRONLY | File::APPEND)
#   #logger           = Logger_ext.new MultiDelegator.delegate(:write, :close).to(STDOUT, log_file)
#   logger.level     = Logger::DEBUG
#   logger.progname  = ''
#   logger.datetime_format = '%d/%m/%Y\t%H:%M:%S'
#   @start_time      = Time.new.to_i
#   logger.formatter = proc do |severity, datetime, progname, msg|
#     severity = severity.green     if severity == "INFO"
#     severity = severity.yellow    if severity == "WARN"
#     severity = severity.red       if severity == "ERROR"
#     severity = severity.red.bold  if severity == "FATAL"
#     severity = severity.magenta   if severity == "DEBUG"
#     severity = severity.blue.bold if severity == "EXECUTE"
#     severity = severity.blue      if severity == "FINISH"
#     message  = ''
#     message << "#{Time.new.to_i - @start_time}\t"
#     message << "#{datetime}\t"
#     message << "#{progname.bold}\t"
#     message << "#{severity}\t"
#     message << "#{msg.dump}\n"
#     message
#   end
#   logger
# end
#
#
# @logger = create_log
# @logger.info('worker')   { 'doing hard work' }
# @logger.warn('worker')   { 'doing hard work' }
# @logger.error('worker')  { 'doing hard work' }
# @logger.debug('worker')  { 'doing hard work' }
# @logger.execute('task1') { 'doing hard work' }
# @logger.finish('task2')  { 'doing hard work' }
# @logger.fatal('worker')  { 'doing hard work' }; exit
# (@logger.fatal('worker') { 'doing hard work' }; exit) if true
