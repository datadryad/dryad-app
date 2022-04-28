module StashEngine
  class JournalOrganization < ApplicationRecord
    self.table_name = 'stash_engine_journal_organizations'
    belongs_to :parent_org, class_name: 'JournalOrganization', optional: true

    # Treat the 'type' column as a string, not a single-inheritance class name
    self.inheritance_column = :_type_disabled

    def journals_sponsored
      StashEngine::Journal.where(sponsor_id: id)
    end
  end
end
