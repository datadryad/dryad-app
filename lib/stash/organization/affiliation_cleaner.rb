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
          aff = StashDatacite::Affiliation.where('LOWER(long_name) = LOWER(?)', name).where.not(ror_id: nil).first
          aff ||= StashDatacite::Affiliation.where('LOWER(long_name) = LOWER(?)', name).last

          if skip_affiliation(aff)
            puts "Found different ROR IDs for \"#{name}\""
            next
          end
          puts "#{index += 1}. Found #{counts} records for \"#{name}\" (id: #{aff.id}), #{aff.ror_id}"
          AffiliationsService.new(aff).make_uniq
        end
      end

      def self.skip_affiliation(aff)
        StashDatacite::Affiliation.where('LOWER(long_name) = LOWER(?)', aff.long_name).where.not(ror_id: nil).pluck(:ror_id).uniq.count > 1
      end
    end
  end
end
