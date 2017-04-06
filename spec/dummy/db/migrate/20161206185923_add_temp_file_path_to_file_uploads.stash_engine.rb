# This migration comes from stash_engine (originally 20160203214606)
class AddTempFilePathToFileUploads < ActiveRecord::Migration
  def change
    add_column :stash_engine_file_uploads, :temp_file_path, :text
  end
end
