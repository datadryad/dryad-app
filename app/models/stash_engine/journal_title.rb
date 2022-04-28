module StashEngine
  class JournalTitle < ApplicationRecord
    self.table_name = 'stash_engine_journal_titles'
    belongs_to :journal

  end
end
