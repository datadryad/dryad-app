module StashEngine
  class JournalRole < ApplicationRecord
    belongs_to :user
    # must contain either a journal or a journal_organization
    belongs_to :journal, optional: true
    belongs_to :journal_organization, optional: true

    scope :admins, -> { where(role: 'admin') }
    scope :org_admins, -> { where(role: 'org_admin') }
  end
end
