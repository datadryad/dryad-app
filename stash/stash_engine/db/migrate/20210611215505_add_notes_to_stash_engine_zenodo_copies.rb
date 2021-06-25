class AddNotesToStashEngineZenodoCopies < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_zenodo_copies, :note, :text
    add_index :stash_engine_zenodo_copies, :note, length: 30
  end
end
