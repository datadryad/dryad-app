class AddTempFilePathToFileUploads < ActiveRecord::Migration
  def change
    add_column :stash_engine_file_uploads, :temp_file_path, :text
  end
end
