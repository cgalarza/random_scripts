#
# Script to replace a string of characters in a file
#

require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: search_and_replace.rb --filename [options]"

  opts.on("-fFILENAME", "--filename=FILENAME", "filename") do |f|
    options[:filename] = f
  end

  opts.on("-mMAP", "--map=MAP", "map") do |f|
    options[:map] = f
  end

  opts.on("-oOUTPUT", "--output", "output") do |f|
    options[:output] = f
  end

end.parse!

raise 'Could not find file' unless File.exists?(options[:filename])

map_file = options[:map] || 'map.yml'
raise 'Could not find map' unless File.exists?(map_file)
map = YAML.load_file(map_file)['map']

text = File.read(options[:filename])

map.sort_by { |k, v| k.length }.reverse.each do |search, replace|
  text.gsub!(search, replace)
end

output = options[:output] ||"#{options[:filename]}.new"

File.open(output, "w") { |f| f.puts text }
