class ChangeFileStateColumn < ActiveRecord::Migration[8.0]
  def up
    change_column :stash_engine_generic_files, :file_state, "ENUM('created', 'copied', 'deleted', 'uploading')"
  end

  def down
    change_column :stash_engine_generic_files, :file_state, "ENUM('created', 'copied', 'deleted')"
  end
end
