#
# Script to retrieve all the member pids associated with the pids given.
# For Fedora 3.
#

require 'optparse'
require 'yaml'
require 'rubydora'
require 'rainbow'
require 'json'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: get_assets.rb --filename --output"

  # Should be a csv with a column name aggregator_pid.
  opts.on("-fFILENAME", "--filename=FILENAME", "filename") do |f|
    options[:filename] = f
  end

  # Will create a csv in the location of output listing the aggregator and asset pids.
  opts.on("-oOUTPUT", "--output=OUTPUT", "output") do |f|
    options[:output] = f
  end

end.parse!


filename = File.expand_path(options[:filename])
raise "Could not find file #{filename}" unless File.exists?(filename)

output = File.expand_path(options[:output])

# Get list of pids.
aggregators = []
CSV.foreach(filename, headers: true) do |row|
  aggregators << row['_pid'] ## NEED TO USE COLUMN NAME
end

fconfig = YAML.load_file(File.join(File.expand_path(File.dirname(__FILE__)), 'fedora.yml'))
repo = Rubydora.connect(url: fconfig['url'], user: fconfig['user'], password: fconfig['password'])

# Query Fedora for assets
headers = ['member_pid', 'parent_pid', 'title']
assets_to_aggregators = []
aggregators.each do |agr_pid|
  ri_query = "select $member $title from <#ri>"\
             " where $member <http://purl.oclc.org/NET/CUL/memberOf> <fedora:#{agr_pid}>"\
             " and $member <info:fedora/fedora-system:def/model#label> $title"
  response = repo.risearch(ri_query, format: 'json', lang: 'itql')
  assets = JSON.parse(response.body)['results']

  if assets.blank? || assets.count.zero?
    puts Rainbow("WARN: #{agr_pid} does not have any assets.").yellow
  end

  assets.each do |asset|
    pid = asset['member'].gsub('info:fedora/', '')
    title = asset['title']
    assets_to_aggregators << [pid, agr_pid, title]
  end
end

# Create aggregator to asset csv.
CSV.open(output, "w") do |csv|
  csv.add_row(headers)
  assets_to_aggregators.each { |row| csv.add_row(row) }
end
