module StashEngine
  class ProcessDate < ApplicationRecord
    self.table_name = 'stash_engine_process_dates'
    belongs_to :processable, polymorphic: true, optional: false
  end
end
