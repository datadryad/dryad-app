class CreateStashDataciteTemporalCoverages < ActiveRecord::Migration
  def change
    create_table :stash_datacite_temporal_coverages do |t|
      t.text :description
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
