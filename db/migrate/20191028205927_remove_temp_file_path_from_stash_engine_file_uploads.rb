class RemoveTempFilePathFromStashEngineFileUploads < ActiveRecord::Migration[4.2]
  def change
    remove_column :stash_engine_file_uploads, :temp_file_path, :text
  end
end
