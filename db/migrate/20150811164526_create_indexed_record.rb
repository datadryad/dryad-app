class CreateIndexedRecord < ActiveRecord::Migration
  def change
    create_table :indexed_records do |t|
      t.references :index_job, foreign_key: true
      t.references :harvested_record, foreign_key: true
      t.datetime :submitted_time
      t.integer :status, default: 0
    end

    # TODO: Remove these once foreign_key works
    add_index :indexed_records, :index_job_id
    add_index :indexed_records, :harvested_record_id
  end
end
