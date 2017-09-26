
      desc "Default Task, Starting point of the Workflow"
      multitask :default , [:log, :datamanager] => [ :test2_normal ]  do |t,args|
        @log.info "The Workflow is now finish"
        #sleep 1
      end
    
