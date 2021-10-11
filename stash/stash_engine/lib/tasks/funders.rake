require 'csv'
require 'byebug'
namespace :funders do
  desc 'Set crossref funders for exact matches'
  task set_crossref_funders: :environment do
    table = nil
    File.open(File.join(__dir__, 'funders/funderNames.csv'), 'r:UTF-8') do |f|
      table = CSV.parse(f.read, headers: true, liberal_parsing: true)
    end

    # the fields are 'uri' and 'primary_name_display', put into a hash for easy lookup by name as key
    lookup = {}
    table.each do |row|
      lookup[row['primary_name_display'].strip.downcase] = row['uri']
    end

    StashDatacite::Contributor.where(contributor_type: 'funder').where('name_identifier_id IS NULL or name_identifier_id = ""')
      .each_with_index do |contrib, idx|
      simple_name = contrib.contributor_name.gsub(/\*$/, '').strip.downcase # remove a star at the end if there is one and downcase
      if lookup[simple_name].present?
        contrib.update!(contributor_name: contrib.contributor_name.gsub(/\*$/, '').strip, name_identifier_id: lookup[simple_name])
      end
      puts "Checked #{idx} funders for ids" if idx % 100 == 0 && idx != 0
    end
  end
end
