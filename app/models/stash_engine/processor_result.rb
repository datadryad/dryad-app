# == Schema Information
#
# Table name: stash_engine_processor_results
#
#  id               :bigint           not null, primary key
#  completion_state :integer
#  message          :text(16777215)
#  processing_type  :integer
#  structured_info  :text(4294967295)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :integer
#  resource_id      :integer
#
module StashEngine
  class ProcessorResult < ApplicationRecord
    self.table_name = 'stash_engine_processor_results'
    belongs_to :resource

    enum :processing_type, { excel_to_csv: 0, compressed_info: 1, frictionless: 2 }
    enum :completion_state, { not_started: 0, processing: 1, success: 2, error: 3 }

  end
end
