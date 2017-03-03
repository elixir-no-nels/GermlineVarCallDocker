# to register the module. This name must start by a capital, use CamelCase and correspond to the class name
@module_name = "DefaultTask"

# The Tool Module itself
# inherit from Toolbase
class DefaultTask < Toolbase

  # Template for the Rake Task
  def step_template()
    @step = %~
      desc "Default Task, Starting point of the Workflow"
      multitask :default , [:log, :datamanager] #{self.add_depend_list} do |t,args|
        @log.info "The Workflow is now finish"
        #sleep 1
      end
    ~
  end

end

