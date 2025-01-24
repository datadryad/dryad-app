# == Schema Information
#
# Table name: stash_engine_journal_issns
#
#  id         :string(191)      not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  journal_id :integer
#
# Indexes
#
#  fk_rails_f3f01a3cbd  (journal_id)
#
# Foreign Keys
#
#  fk_rails_...  (journal_id => stash_engine_journals.id)
#
module StashEngine
  class JournalIssn < ApplicationRecord
    self.table_name = 'stash_engine_journal_issns'
    belongs_to :journal, class_name: 'StashEngine::Journal', inverse_of: :issns
    ISSN = /\A[0-9]{4}-[0-9]{3}[0-9X]\z/
    alias_attribute :issn, :id

    validates :issn, format: { with: ISSN, message: 'ISSN %{value} format is invalid' }, uniqueness: { message: 'ISSN %{value} is already in use' }
  end
end
