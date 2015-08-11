class CreateHarvestedRecords < ActiveRecord::Migration
  def change
    create_table :harvested_records do |t|
      t.text :identifier
      t.datetime :timestamp
      t.boolean :deleted
      t.text :content_path
      t.references :harvest_job
    end
  end
end
