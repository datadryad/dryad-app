class DropStashEngineSoftwareUploads < ActiveRecord::Migration[5.2]
  def change
    drop_table :stash_engine_software_uploads
  end
end
