class CreateStashEngineImageUploads < ActiveRecord::Migration
  def change
    create_table :stash_engine_image_uploads do |t|
      t.string :image_name
      t.string :image_type
      t.integer :image_size
      t.integer :resource_id
      t.datetime :image_updated_at

      t.timestamps null: false
    end
  end
end
