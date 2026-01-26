class RenameSubmittedColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :stash_engine_process_dates, :submitted, :queued
    rename_column :stash_engine_curation_stats, :new_datasets_to_submitted, :new_datasets_to_queued
  end
end
