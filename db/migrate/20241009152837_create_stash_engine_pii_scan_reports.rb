class CreateStashEnginePiiScanReports < ActiveRecord::Migration[7.0]
  def change
    create_table :stash_engine_pii_scan_reports do |t|
      t.text :report
      t.belongs_to :generic_file, foreign_key: { to_table: :stash_engine_generic_files }, type: :integer,
                   index: {name: "index_stash_engine_pii_scan_reports_on_generic_file_id"}
      t.string :status
      t.timestamps
    end
  end
end
