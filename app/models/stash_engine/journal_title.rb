# == Schema Information
#
# Table name: stash_engine_journal_titles
#
#  id                   :bigint           not null, primary key
#  title                :string(191)
#  journal_id           :integer
#  show_in_autocomplete :boolean
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
module StashEngine
  class JournalTitle < ApplicationRecord
    self.table_name = 'stash_engine_journal_titles'
    belongs_to :journal

  end
end
