class DropStashEngineFileUploads < ActiveRecord::Migration[5.2]
  def change
    drop_table :stash_engine_file_uploads
  end
end
