#!/usr/bin/env ruby

# Usage: rake -P | rake-prereqs-dot | dotty -
#
# rake -f workflow_test_default.rb -P | ruby graph.rb > graph.dot
# dot graph.dot -Tpng -o graph.png
# or open the dot file with dotty or omnigraffle



# Convert the output of `rake -P/--prereqs`
# ("Display the tasks and dependencies, then exit.")
# to a graphviz graph

# Sample input
# -8<-
# rake check:osc
# rake check:syntax
# rake console
# rake osc:build
#     check:osc
#     package
# rake osc:commit
#     osc:build
# rake osc:sr
#     osc:commit
# rake package
#     check:syntax
#     tarball
# rake tarball
# -8<-

require 'optparse'

## Arguments Parser

# Help message
def usage(options)
  puts 'Usage : '
  puts "-r    --rakefile RakefileName Load the Rakefile that discribe the workflow. Value: #{options[:conf]}"
  exit
end

# Default values
options = {}
options[:rakefile]    = 'RakeFile.rake'

# Parser
OptionParser.new do |opts|
  opts.banner = 'Usage: example.rb [options]'

  opts.on('-r', '--rakefile RakefileName', String, "Load Rakefile file that discribe the workflow. Default: #{options[:conf]}") do |arg|
    options[:rakefile] = arg
  end

  opts.on('-h', '--help', 'Help') do |arg|
    usage(options) if arg
  end

end.parse!

# extract the dependencie tree between tasks from the RakeFile
rake_struct   = `rake -f "#{options[:rakefile]}" -P`
body_struct   = false
header_passed = false

# Generate a Grafviz .dot file
dotfile     = "digraph g {"

task = '?'
rake_struct.each_line do |line|
  header_passed = true if line.include? 'rake '
  next if not header_passed
  body_struct = true if line.include? 'rake default'
  line.chomp!
  if line =~ /^rake (.*)/
    task = $1
    next if not body_struct
    next if line.include? task
    next if line.include? 'default'
    dotfile << "\"#{task}\" -> \n"
  else
    dotfile << "\"#{task}\" -> \"#{line.strip}\";\n"
  end
end

dotfile << '}'


# print the .dot file content
puts dotfile
