# frozen_string_literal: true

module Stash
  module Organization
    class AffiliationUpdater

      def self.perform
        puts ''
        puts "Starting affiliation update: #{Time.now}"
        StashDatacite::Affiliation.joins(:ror_org).where('long_name != name').find_in_batches(batch_size: 100) do |group|
          group.each do |record|
            puts "Updating affiliation with id: #{record.id} from \"#{record.long_name}\" to \"#{record.ror_org.name}\""
            record.update(long_name: record.ror_org.name)
          end
          sleep 5
        end
      end
    end
  end
end
