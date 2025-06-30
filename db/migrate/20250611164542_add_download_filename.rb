class AddDownloadFilename < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_generic_files, :download_filename, :text
    add_index :stash_engine_generic_files, :download_filename, length: { download_filename: 100 }
  end
end
