require 'csv'
require 'byebug'
require_relative 'funders/utils'

namespace :funders do
  desc 'Set crossref funders for exact matches'
  task set_crossref_funders: :environment do
    # name as key, value is fundref doi
    lookup = Funders::Utils.new.lookup

    StashDatacite::Contributor.where(contributor_type: 'funder').where('name_identifier_id IS NULL or name_identifier_id = ""')
      .each_with_index do |contrib, idx|
      simple_name = contrib.contributor_name.gsub(/\*$/, '').strip.downcase # remove a star at the end if there is one and downcase

      contrib.update!(contributor_name: lookup[simple_name][:name], name_identifier_id: lookup[simple_name][:uri]) if lookup[simple_name].present?

      puts "Checked #{idx} funders for missing ids" if idx % 100 == 0 && idx != 0
    end
  end

  desc 'export similarity for unmatched to CSV'
  task similarity_csv: :environment do
    util = Funders::Utils.new

    sql = <<-SQL
      SELECT REPLACE(c.contributor_name, '*', '') as contrib, COUNT(*) as count FROM dcs_contributors c
      JOIN stash_engine_resources res
      ON c.`resource_id` = res.id
      WHERE res.meta_view = 1 AND
      c.contributor_type = "funder" AND
      (c.name_identifier_id IS NULL OR c.name_identifier_id = '')
      GROUP BY contrib
      ORDER BY COUNT(*) DESC
    SQL

    records_array = ActiveRecord::Base.connection.exec_query(sql)

    CSV.open('funder_suggestions.csv', 'wb') do |csv|

      csv << %w[database_funder number sugg_funder sugg_id]

      count = 0
      records_array.rows.each do |i|
        count += 1
        match = util.best_match(name: i[0]) || {}

        csv << [i[0].strip, i[1], match[:name], match[:uri]]
        puts "checked #{count}" if count % 100 == 0
      end
      puts 'Output file funder_suggestions.csv'
    end
  end

  desc 'update IDs for re-importing spreadsheet for items manually matched/entered'
  task import_manual_lookup_csv: :environment do
    CSV.foreach('/Users/sfisher/Downloads/Funders-10-11-21.csv', headers: true) do |row|
      # find 'database_funder' and 'sugg_id', if 'sugg_id' is filled in then update those items in the database that match
      # the string to have that funder id
      next if row['sugg_id'].blank?

      StashDatacite::Contributor
        .where("contributor_name LIKE ? AND contributor_type = 'funder' AND (name_identifier_id IS NULL OR name_identifier_id = '')",
               "#{row['database_funder'].strip}%").each_with_index do |contrib, idx|

        better_name = contrib.contributor_name.gsub(/[* ]+$/, '') # removes stars and spaces from the end
        if better_name.downcase == row['database_funder'].strip.downcase
          puts "#{idx} -- Updating: #{row['database_funder']} to have id #{row['sugg_id']}"
          contrib.update(contributor_name: better_name, name_identifier_id: row['sugg_id'].strip)
        end
      end

      puts ''
    end
  end
end
