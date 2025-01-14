# frozen_string_literal: true

module Stash
  module Organization
    class AffiliationUpdater

      def self.perform
        puts ''
        puts "Starting affiliation update: #{Time.now}"

        index = 0
        StashDatacite::Affiliation.joins(:ror_org).where('long_name != name').find_each do |record|
          puts "Updating affiliation with id: #{record.id} from \"#{record.long_name}\" to \"#{record.ror_org.name}\""
          record.update(long_name: record.ror_org.name)

          index += 1
          sleep 3 if index % 1000 == 0
        end
      end
    end
  end
end
