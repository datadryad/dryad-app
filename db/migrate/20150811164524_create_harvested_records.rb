class CreateHarvestedRecords < ActiveRecord::Migration
  def change
    create_table :harvested_records do |t|
      t.text :identifier
      t.datetime :timestamp
      t.boolean :deleted
      t.references :harvest_job, foreign_key: true
    end

    # TODO: Remove these once foreign_key works
    add_index :harvested_records, :harvest_job_id
  end
end
