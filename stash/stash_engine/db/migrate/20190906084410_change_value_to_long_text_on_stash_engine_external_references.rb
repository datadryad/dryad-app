class ChangeValueToLongTextOnStashEngineExternalReferences < ActiveRecord::Migration[4.2]
  def change
    change_column :stash_engine_external_references, :value, :longtext
  end
end
