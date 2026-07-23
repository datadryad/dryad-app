# frozen_string_literal: true

module Stash
  module Organization
    class ContributorNameUpdater

      def self.perform
        puts ''
        puts "Starting contributors name update: #{Time.now}"

        index = 0
        StashDatacite::Contributor.joins(:ror_org)
          .where(stash_engine_ror_orgs: { status: StashEngine::RorOrg.statuses[:active] })
          .where('stash_engine_ror_orgs.name != dcs_contributors.contributor_name OR dcs_contributors.contributor_name is NULL').find_each do |record|
          puts "Updating contributor with id: #{record.id} from \"#{record.contributor_name}\" to \"#{record.ror_org.name}\""
          record.update(contributor_name: record.ror_org.name)

          index += 1
          sleep 3 if index % 1000 == 0
        end
      end
    end
  end
end
