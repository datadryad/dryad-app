class DropStashEngineImageUploads < ActiveRecord::Migration[4.2]
  def up
    drop_table :stash_engine_image_uploads
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
