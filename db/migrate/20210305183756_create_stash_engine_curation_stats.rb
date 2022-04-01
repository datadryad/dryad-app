class CreateStashEngineCurationStats < ActiveRecord::Migration[5.2]
  def change
    create_table :stash_engine_curation_stats do |t|
      t.datetime :date
      t.integer :datasets_curated
      t.integer :new_datasets_to_submitted
      t.integer :new_datasets_to_peer_review
      t.integer :datasets_to_aar
      t.integer :datasets_to_published
      t.integer :datasets_to_embargoed
      t.integer :author_revised
      t.integer :author_versioned      
      t.timestamps 
    end
  end
end
