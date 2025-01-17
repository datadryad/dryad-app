class RenameStashEnginePiiScanReportsTable < ActiveRecord::Migration[7.0]
  def change
    rename_index :stash_engine_pii_scan_reports, 'index_stash_engine_pii_scan_reports_on_generic_file_id', 'index_stash_engine_sensitive_data_reports_on_generic_file_id'
    rename_table :stash_engine_pii_scan_reports, :stash_engine_sensitive_data_reports
  end
end
