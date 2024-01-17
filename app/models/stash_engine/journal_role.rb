# == Schema Information
#
# Table name: stash_engine_journal_roles
#
#  id                      :integer          not null, primary key
#  journal_id              :integer
#  user_id                 :integer
#  role                    :string(191)
#  created_at              :datetime
#  updated_at              :datetime
#  journal_organization_id :integer
#
module StashEngine
  class JournalRole < ApplicationRecord
    self.table_name = 'stash_engine_journal_roles'
    belongs_to :user
    # must contain either a journal or a journal_organization
    belongs_to :journal, optional: true
    belongs_to :journal_organization, optional: true

    scope :admins, -> { where(role: 'admin') }
    scope :org_admins, -> { where(role: 'org_admin') }
  end
end
