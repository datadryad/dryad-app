class AddDeleteCalculationDateToProcessingDates < ActiveRecord::Migration[7.0]
  def change
    add_column :stash_engine_process_dates, :delete_calculation_date, :datetime, after: :last_status_date
    add_index :stash_engine_process_dates, :delete_calculation_date
  end
end
