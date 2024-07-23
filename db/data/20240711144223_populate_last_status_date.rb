# frozen_string_literal: true

class PopulateLastStatusDate < ActiveRecord::Migration[7.0]
  def up
    StashEngine::Resource.find_in_batches(batch_size: 1000) do |batch|
      batch.each do |res|
        status = res.current_curation_status
        date = res.last_curation_activity.created_at

        res.curation_activities.map { |q| [q.status, q.created_at] }.sort { |a, b| b[1] <=> a[1] }.each do |item|
          break if status != item[0]
          date = item[1]
        end
        res.process_date.update_columns(last_status_date: date, delete_calculation_date: date)
        res.identifier.process_date.update_columns(delete_calculation_date: date)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
