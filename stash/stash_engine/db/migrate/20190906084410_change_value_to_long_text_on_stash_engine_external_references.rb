class ChangeValueToLongTextOnStashEngineExternalReferences < ActiveRecord::Migration
  def change
    change_column :stash_engine_external_references, :value, :longtext
  end
end
