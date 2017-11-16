#
# Script to ensure that all items that were in the original solr core are now
# in hyacinth.
#
in_solr_ids = IO.readlines("in_solr.csv").map(&:strip!)

in_hyacinth_ids = File.readlines("in_hyacinth.csv").map(&:strip!)
puts "in_hyacinth.csv has #{in_hyacinth_ids.count}"

not_migrated = File.readlines("do_not_publish.csv").map(&:strip!)

missing = []
in_solr_ids.each do |id|
  next if not_migrated.include?(id)
  if !in_hyacinth_ids.include?(id)
    missing << id
  end
end

puts "Missing #{missing.count}:\n#{missing.join("\n")}"
