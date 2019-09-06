class ChangeValueToLongTextOnStashEngineExternalReferences < ActiveRecord::Migration
  def change
    add_column :stash_engine_external_references, :value, :longtext
  end
end
