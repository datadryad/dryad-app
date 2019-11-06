class CreateStashEngineCounterStats < ActiveRecord::Migration
  def change
    create_table :stash_engine_counter_stats do |t|
      t.references :identifier
      t.integer :citation_count
      t.integer :unique_investigation_count
      t.integer :unique_request_count

      t.timestamps null: false
    end
  end
end
