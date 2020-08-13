class AddIndexToFileUploadsUploadFilename < ActiveRecord::Migration[4.2]
  def change
    add_index(:stash_engine_file_uploads, :upload_file_name, length: { upload_file_name: 100 })
    add_index(:stash_engine_file_uploads, :resource_id)
    add_index(:stash_engine_file_uploads, :file_state)
  end
end
