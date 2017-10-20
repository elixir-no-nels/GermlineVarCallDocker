# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "Test_Docker"

class Test_Docker < Toolbase

  ## Template for the Rake Task

  def get_config_template
    erb_template = %~
     docker_images = <%= @opt_parser.get      from: 'docker_image', default_value: '',       required: false, type: String, comment: 'provide a docker images ID if you want run a container' %>
     docker_opts   = <%= @opt_parser.get      from: 'docker_opts',   default_value: '',       required: false, type: String, comment: 'provide options for docker if needed' %>
     wait_time     = <%= @opt_parser.get      from: 'wait_time',    default_value: 1,        required: true,  type: Integer, comment: 'Time to wait to simulate a long process' %>
     arg_for_tool  = <%= @opt_parser.get_args from: 'tool_d',       default_value: [],       comment: 'Argument for the Tool Tool1' %>
    ~
  end

  def tool_template
    template = %~

      #-- Commands

      # Hello from a container
      cmd = Command.new task_name: task_name, log: @log
      cmd.line << "echo hello from a container && sleep \#{wait_time} \#{arg_for_tool}"
      cmd.run compress_spaces: true, debug_mode: debug, docker_id: docker_images, docker_options: docker_opts
    ~
  end

end
