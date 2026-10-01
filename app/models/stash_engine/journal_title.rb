# == Schema Information
#
# Table name: stash_engine_journal_titles
#
#  id                   :bigint           not null, primary key
#  show_in_autocomplete :boolean
#  title                :string(191)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  journal_id           :integer
#
module StashEngine
  class JournalTitle < ApplicationRecord
    self.table_name = 'stash_engine_journal_titles'
    belongs_to :journal

  end
end
