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
  end
end
