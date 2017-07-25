#
# Script to separate really long CSVs
#

require 'optparse'
require 'csv'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: split_csv.rb --filename [options]"

  opts.on("-fFILENAME", "--filename=FILENAME", "filename") do |f|
    options[:filename] = f
  end
end.parse!

def export_to_file(table, filepath)
  CSV.open(filepath, 'w', encoding: 'UTF-8') do |csv|
    # Sorting header by alphabetical order. If begining of header is the same
    # headers are stored by number.
    sorted_headers = table.headers.sort do |a, b|
      regex = /^(\w+)-(\d+):(.*)$/
      a_match = regex.match(a)
      b_match = regex.match(b)
      if a_match && b_match && (a_match[1] == b_match[1])
        if a_match[2] == b_match[2]
          a_match[3] <=> b_match[3]
        else
          a_match[2].to_i <=> b_match[2].to_i
        end
      else
        a <=> b
      end
    end

    csv.add_row(sorted_headers)
    table.each do |row|
      csv.add_row(row.fields(*sorted_headers))
    end
  end
end

# Returns headers of empty columns
def empty_columns(table)
  h = table.headers.clone
  table.each do |row|
    h.reject! { |header| !(row[header].nil? || row[header].empty?) }
  end
  h
end


filename = options[:filename]
extension = File.extname(filename)
file = File.basename(filename, extension)
csv_a = File.join(File.dirname(filename), "#{file}-a#{extension}")
csv_b = File.join(File.dirname(filename), "#{file}-b#{extension}")

# rows = CSV.read(filename, headers: true, encoding: 'utf-8')
table_a = CSV::Table.new(CSV.read(filename, headers: true, encoding: 'utf-8'))
table_b = CSV::Table.new(CSV.read(filename, headers: true, encoding: 'utf-8'))


names = table_a.headers.select { |h| /^name-\d+.+$/.match(h) }
required_columns = table_a.headers.select { |h| /^_.+$/.match(h) }
names.each do |h|
  table_a.delete(h)
end
export_to_file(table_a, csv_a)

# Names CSVs
(table_b.headers - (required_columns + names)).each do |h|
  table_b.delete(h)
end
empty_columns(table_b).each do |h|
  table_b.delete(h)
end
export_to_file(table_b, csv_b)
