# frozen_string_literal: true

module Stash
  module Organization
    class AffiliationCleaner

      def self.perform
        puts ''
        puts '========================================================================================'
        puts "Starting affiliation cleaner: #{Time.now}"

        index = 0
        duplicates = StashDatacite::Affiliation.select(:long_name).group(:long_name).having('COUNT(*) > 1').count
        puts "Found #{duplicates.count} duplicated names used in #{duplicates.sum { |a| a[1] }} records."
        duplicates.each do |name, counts|
          aff = StashDatacite::Affiliation.find_by(long_name: name)
          puts "#{index += 1}. Found #{counts} records for \"#{name}\" (id: #{aff.id})"
          AffiliationsService.new(aff).make_uniq
        end
      end
    end
  end
end
