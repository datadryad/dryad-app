module StashEngine
  class JournalIssn < ApplicationRecord
    self.table_name = 'stash_engine_journal_issns'
    belongs_to :journal, class_name: 'StashEngine::Journal'
    ISSN = /\A[0-9]{4}-[0-9]{3}[0-9X]\z/

    validates :id, format: ISSN
  end
end
