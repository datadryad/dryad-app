class RemoveOldCedar < ActiveRecord::Migration[8.0]
  def change
    remove_column :stash_engine_resources, :old_cedar_json, :text
  end
end
