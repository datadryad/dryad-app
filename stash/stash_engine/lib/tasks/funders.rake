require 'csv'
require 'byebug'
namespace :funders do
  desc 'Set crossref funders for exact matches'
  task set_crossref_funders: :environment do
    table = nil
    File.open(File.join(__dir__, 'funders/funderNames.csv'), "r:UTF-8") do |f|
      table = CSV.parse(f.read, headers: true, liberal_parsing: true)
    end

    # the fields are 'uri' and 'primary_name_display', put into a hash for easy lookup by name as key
    lookup = {}
    table.each do |row|
      lookup[row['primary_name_display'].strip.downcase] = row['uri']
    end



  end
end