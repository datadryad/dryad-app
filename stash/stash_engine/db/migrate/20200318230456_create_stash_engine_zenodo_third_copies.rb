class CreateStashEngineZenodoThirdCopies < ActiveRecord::Migration
  def change
    create_table :stash_engine_zenodo_third_copies do |t|
      t.column :state, "ENUM('enqueued', 'replicating', 'finished', 'error') DEFAULT 'enqueued'", index: true
      t.integer :deposition_id, index: true
      t.text :error_info
      t.references :identifier, index: true
      t.references :resource, index: true

      t.timestamps null: false
    end
  end
end
