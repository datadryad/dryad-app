class CreateProcessorResults < ActiveRecord::Migration[6.1]
  def change
    create_table :stash_engine_processor_results do |t|
      t.integer :resource_id
      t.integer :processing_type
      t.integer :parent_id
      t.integer :completion_state
      t.text :message, :limit => 16.megabytes - 1
      t.text :structured_info, :limit => 4.gigabytes - 1

      t.timestamps
    end
  end
end
