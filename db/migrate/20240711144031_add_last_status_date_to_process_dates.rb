class AddLastStatusDateToProcessDates < ActiveRecord::Migration[7.0]
  def change
    add_column :stash_engine_process_dates, :last_status_date, :datetime, after: :withdrawn
    add_index :stash_engine_process_dates, :last_status_date
  end
end
