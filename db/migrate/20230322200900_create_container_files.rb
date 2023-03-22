class CreateContainerFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :stash_engine_container_files do |t|
      t.integer :data_file_id, index: true
      t.text :path
      t.string :mime_type, index: true
      t.integer :size

      t.timestamps
    end
  end
end
