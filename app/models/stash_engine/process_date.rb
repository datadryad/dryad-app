# == Schema Information
#
# Table name: stash_engine_process_dates
#
#  id                      :bigint           not null, primary key
#  approved                :datetime
#  curation_end            :datetime
#  curation_start          :datetime
#  delete_calculation_date :datetime
#  deleted_at              :datetime
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
#  index_stash_engine_process_dates_on_deleted_at               (deleted_at)
#  index_stash_engine_process_dates_on_last_status_date         (last_status_date)
#
module StashEngine
  class ProcessDate < ApplicationRecord
    self.table_name = 'stash_engine_process_dates'
    acts_as_paranoid
    has_paper_trail

    belongs_to :processable, polymorphic: true, optional: false

    def wait_period
      status_checks = {
        in_progress: 1.month,
        action_required: 1.month,
        peer_review: 6.months
      }
      status_checks[processable.current_curation_status.to_sym]
    end

    def notification_start_date
      return nil unless processable.is_a?(StashEngine::Resource)
      return nil unless delete_calculation_date && wait_period

      delete_calculation_date + wait_period
    end

    def delete_date
      return nil if delete_calculation_date.blank?

      delete_calculation_date + 1.year
    end

    def notification_date
      date = notification_start_date
      return nil if date.blank?

      date += 1.month while date.past?
      date
    end

  end
end
