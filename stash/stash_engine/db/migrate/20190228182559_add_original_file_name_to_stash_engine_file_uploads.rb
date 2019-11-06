class AddOriginalFileNameToStashEngineFileUploads < ActiveRecord::Migration
  def change
    add_column :stash_engine_file_uploads, :original_filename, :text
  end
end
