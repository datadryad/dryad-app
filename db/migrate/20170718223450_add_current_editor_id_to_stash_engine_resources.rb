class AddCurrentEditorIdToStashEngineResources < ActiveRecord::Migration[4.2]
  def change
    change_table :stash_engine_resources do |t|
      t.integer :current_editor_id
      t.index :current_editor_id
    end
  end
end
