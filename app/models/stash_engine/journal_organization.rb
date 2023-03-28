module StashEngine
  class JournalOrganization < ApplicationRecord
    self.table_name = 'stash_engine_journal_organizations'
    belongs_to :parent_org, class_name: 'JournalOrganization', optional: true

    # Treat the 'type' column as a string, not a single-inheritance class name
    self.inheritance_column = :_type_disabled

    # journals sponsored directly by this org
    def journals_sponsored
      StashEngine::Journal.where(sponsor_id: id)
    end

    # journals sponsored at any level by this org and its children
    def journals_sponsored_deep
      j = StashEngine::Journal.where(sponsor_id: id)
      orgs_included&.each do |suborg|
        j += suborg.journals_sponsored
      end
      j
    end

    # All organizations that are part of this organization,
    # at any level of hierarchy
    def orgs_included
      suborgs = StashEngine::JournalOrganization.where(parent_org: id)
      return nil if suborgs.blank?

      all_orgs = []

      suborgs.each do |sub|
        all_orgs << sub
        all_orgs += sub.orgs_included if sub.orgs_included.present?
      end
      all_orgs
    end
  end
end
