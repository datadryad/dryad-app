class AddStateToFileUploads < ActiveRecord::Migration
  def up
    add_column :stash_engine_file_uploads, :file_state, "ENUM('created', 'copied', 'deleted')"
  end

  def down
    remove_column :stash_engine_file_uploads, :file_state
  end
end
