class CreateFileUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :file_uploads do |t|
      t.integer :user_id
      t.integer :file_id
      t.integer :resource_id
      t.string :key
      t.string :upload_id
      t.string :status
      t.bigint :size
      t.integer :part_number

      t.timestamps
    end
  end
end
