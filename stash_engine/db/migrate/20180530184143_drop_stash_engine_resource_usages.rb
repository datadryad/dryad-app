class DropStashEngineResourceUsages < ActiveRecord::Migration
  def up
    drop_table :stash_engine_resource_usages
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
