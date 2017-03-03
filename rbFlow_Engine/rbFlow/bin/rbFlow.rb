#!/usr/bin/env ruby

Process.setproctitle("rbFlow") # Change the name of the process

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib/rbFlow")

# list of external tool modules loaded
@module_list = []

require 'optparse'
require 'rbFlow'    # will Populate @module_list

## Arguments Parser

# Help message
def usage(options)
  puts 'Usage : '
  puts "-c    --conf FILE.conf Load yaml conf file that discribe the workflow. Value: #{options[:conf]}"
  puts "-r    --run            Run the workflow now.                           Value: #{options[:run_now]}"
  puts "-d    --debug          Show debug messages                             Value: #{options[:debug]}"
  exit
end

# Default values
options = {}
options[:conf]    = 'config.yaml'
options[:run_now] = false
options[:debug]   = false      # debug mode

# Parser
OptionParser.new do |opts|
  opts.banner = 'Usage: example.rb [options]'

  opts.on('-c', '--conf FILE.conf', String, "Load yaml conf file that discribe the workflow. Default: #{options[:conf]}") do |arg|
    options[:conf] = arg
  end

  opts.on('-r', '--run', "Run the workflow now. Default: #{options[:run_now]}") do |arg|
    options[:run_now] = arg
  end

  opts.on('-d', '--debug', "Show debug messages. Default: #{options[:debug]}") do |arg|
    options[:debug] = arg
  end

  opts.on('-h', '--help', 'Help') do |arg|
    usage(options) if arg
  end

end.parse!

## Run the Workflow.
begin
  workflow = Workflow.new module_list: @module_list
  workflow.loadconfig file: options[:conf]
  workflow.debug = true if options[:debug]
  workflow.create_workflow
  workflow.close_workflow
  workflow.run if options[:run_now] == true
  workflow.close
  exit true
end
