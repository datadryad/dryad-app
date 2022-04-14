class AddRetriesToStashEngineZenodoCopies < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_zenodo_copies, :retries, :integer, default: 0
    add_index :stash_engine_zenodo_copies, :retries
  end
end
