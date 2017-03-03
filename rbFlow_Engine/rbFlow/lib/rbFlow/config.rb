require 'yaml'

# Class used to read and parse the yaml configuration file
# Return a structure based on the YAML structure
class Configotron
  attr_accessor :data

  def load(filename)
    if File.file?(filename)
      @data = YAML.load_file(filename)
    else
      puts "#{filename} not found"
      exit
    end
  end
  #
  # def save(data, filename)
  #   if File.file?(filename)
  #     now = Time.now
  #     new_name = filename + now.year + "_" + now.month + "_" + now.day + "_" + now.hour + "_" + now.min + "_" + now.sec
  #     FileUtils.mv(filename, new_name)
  #     puts "#{filename} config file already exist, moved to #{new_name}"
  #   end
  #   dest = File.open(filename, "w")
  #   dest.puts @data.to_yaml
  #   dest.close
  # end
end