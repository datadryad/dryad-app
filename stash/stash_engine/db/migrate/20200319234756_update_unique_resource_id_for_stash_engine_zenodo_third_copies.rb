class UpdateUniqueResourceIdForStashEngineZenodoThirdCopies < ActiveRecord::Migration[4.2]
  def change
    remove_index :stash_engine_zenodo_third_copies, :resource_id
    add_index :stash_engine_zenodo_third_copies, :resource_id, unique: true
  end
end
