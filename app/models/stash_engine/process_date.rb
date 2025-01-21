# == Schema Information
#
# Table name: stash_engine_process_dates
#
#  id                      :bigint           not null, primary key
#  approved                :datetime
#  curation_end            :datetime
#  curation_start          :datetime
#  delete_calculation_date :datetime
#  last_status_date        :datetime
#  peer_review             :datetime
#  processable_type        :string(191)
#  processing              :datetime
#  submitted               :datetime
#  withdrawn               :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  processable_id          :integer
#
# Indexes
#
#  index_process_dates_on_processable_id_and_type               (processable_id,processable_type) UNIQUE
#  index_stash_engine_process_dates_on_delete_calculation_date  (delete_calculation_date)
#  index_stash_engine_process_dates_on_last_status_date         (last_status_date)
#
module StashEngine
  class ProcessDate < ApplicationRecord
    self.table_name = 'stash_engine_process_dates'
    belongs_to :processable, polymorphic: true, optional: false
  end
end
