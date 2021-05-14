module StashEngine
  class JournalOrganization < ApplicationRecord
    belongs_to :parent_org, class_name: 'JournalOrganization', optional: true

    def journals_sponsored
      StashEngine::Journal.where(sponsor_id: id)
    end
  end
end
