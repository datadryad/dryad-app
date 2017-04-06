# This migration comes from stash_engine (originally 20150929170417)
class CreateStashEngineFileUploads < ActiveRecord::Migration
  def change
    create_table :stash_engine_file_uploads do |t|
      t.string :upload_file_name
      t.string :upload_content_type
      t.integer :upload_file_size
      t.integer :resource_id
      t.datetime :upload_updated_at

      t.timestamps null: false
    end
  end
end
