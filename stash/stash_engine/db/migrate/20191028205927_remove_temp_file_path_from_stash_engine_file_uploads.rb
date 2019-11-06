class RemoveTempFilePathFromStashEngineFileUploads < ActiveRecord::Migration
  def change
    remove_column :stash_engine_file_uploads, :temp_file_path, :text
  end
end
