class AddRetriesToStashEngineZenodoCopies < ActiveRecord::Migration
  def change
    add_column :stash_engine_zenodo_copies, :retries, :integer, default: 0
    add_index :stash_engine_zenodo_copies, :retries
  end
end
