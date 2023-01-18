module StashEngine
  class ProcessorResult < ApplicationRecord
    self.table_name = 'stash_engine_processor_results'
    belongs_to :resource

    enum processing_type: { excel_to_csv: 0, compressed_info: 1, frictionless: 2 }
    enum completion_state: { not_started: 0, processing: 1, success: 2, error: 3 }

  end
end
