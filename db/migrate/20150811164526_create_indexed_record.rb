class CreateIndexedRecord < ActiveRecord::Migration
  def change
    create_table :indexed_records do |t|
      t.references :index_job
      t.references :harvested_record
      t.datetime :submitted_time
      t.integer :status, default: 0
    end
  end
end
