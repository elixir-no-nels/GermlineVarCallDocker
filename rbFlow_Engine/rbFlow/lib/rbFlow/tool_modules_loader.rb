# Load all Ruby file store in modules, used as "Tools Module".
# Files contain a class herit from ToolBase and define the
# template used to write the Rake Task

modules_registered = 0
modules_list       = []

# populate modules_list with files
Dir.chdir(File.dirname(__FILE__)) do
  # from modules_list
  Dir['../system_modules/*.rb'].each do |module_file|
    modules_list.push module_file
  end
  # from tool_modules
  Dir['../tool_modules/*.rb'].each do |module_file|
    modules_list.push module_file
  end
end

# include all modules
puts "\n\nLoading Template Rake Task Modules"
puts '-------------------------------------------------------------'
modules_list.each do |module_file|
  @module_name = ''
  require_relative module_file
  @module_list.push @module_name
  modules_registered = modules_registered + 1
  print "#{@module_name}".ljust(25)
  puts  "\tfrom\t#{module_file} "
  # Check errors
  fail('No registration found for the last extension file loaded')        if @module_list.size      != modules_registered
  fail("Duplicate name for #{@module_name}")                              if @module_list.uniq.size != @module_list.size
  fail("@module_name and Class name are not identical in #{module_file}") if not eval("defined?(#{@module_name}) && #{@module_name}.is_a?(Class)")
end
puts "-------------------------------------------------------------\n\n\n"
