# Parse a hash with some options.
#
#  @option = ToolOptions.new with: a_hash
#  input_dir = @options.get from: 'input_dir', required: true, default_value: 'input', type: String, comment: 'Short Description'
#  # Test if no error
#  if @options.errors?
#    puts @options.errors
#    puts @options.doc
#  end
#  # Use
#  input_dir
#

class ToolOptions
  attr_accessor :error, :doc

  def initialize( from: '', name: '', log: '' )
    @options  = from # A hash containing options for the task to configure
    @taskname = name # The task name
    @log      = log  # the log object to use
    @errors   = []   # To store errors of options
    @doc      = []   # to store documentation of all options
  end

  # parse options and check type and presence for required ones. Also Generate a Help text to print in case of error.
  def get( from: '', type: String, required: false, default_value: false, comment: '')
    # from: contain the key used for the current option
    # test errors
    step_options = @options['step_options']
    error = ''
    # a required option is missing ?
    error = "#{from} declaration is missing" if step_options[from].nil? and required == true
    # a option is with a wrong type ?
    # Note: With Ruby version < 2.4.0 there is problem Integer from yaml are detected as Fixnum, that can be fixed in the yaml by replacing Integer by Fixnum type
    error = "#{from} should be a #{type}, a #{step_options[from].class} is provided" if not step_options[from].nil? and step_options[from].class != type
    # Auto documentation of this option
    @doc.push "Option from: #{from},\ttype: #{type},\trequired: #{required},\tdefault_value :#{default_value},\tcomment :#{comment}"
    # use a default value ?
    step_options[from] ||= default_value if default_value  # the ||= operator affect a variable only if this variable is nil or false
    # Add quotes for empty string and nil
    step_options[from] = "\"#{step_options[from]}\"" if step_options[from].class == String # return String with quotes
    step_options[from] = "\"\"" if step_options[from].nil?   # return "" if nil
    # If no error found return the value else return an empty string and add the error in the @errors list
    if error == ''
      step_options[from]
    else
      @errors.push error
      return ''
    end
  end

  # to get command line argument for a command
  def get_args(  from: '', required: false, default_value: [], comment: '' )
    cmd_options = @options['command_line_options'][from]
    # Auto documentation of this option
    @doc.push "Option to pass arguments from: #{from},\tdefault_value :#{default_value},\tcomment :#{comment}"
    if cmd_options.class == Array
      cmd_options = cmd_options.join ' '
      cmd_options = "\"#{cmd_options}\"" # return with quotes
    else
      @errors.push " Arguments option #{from} should be an Array. #{cmd_options.class} found"
    end
  end

  # check if we encouter errors
  def check_error
    if @errors.empty?
      false
    else
      @log.error(@taskname) { "--- Configuration for #{@taskname} ---" }
      @doc.each do |doc|
        @log.error(@taskname) { "#{doc}" }
      end
      @log.error(@taskname) { "--- Errors found for #{@taskname} ---" }
      @errors.each do |error|
        @log.error(@taskname) { " #{error}" }
      end
      @log.fatal(@taskname) { 'terminated' }; exit
    end
  end

end
