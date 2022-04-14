class CreateStashEngineFileUploads < ActiveRecord::Migration[4.2]
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
