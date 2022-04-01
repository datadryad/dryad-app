class AddOriginalFileNameToStashEngineFileUploads < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_file_uploads, :original_filename, :text
  end
end
