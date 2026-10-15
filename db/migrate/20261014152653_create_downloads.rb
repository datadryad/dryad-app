class CreateDownloads < ActiveRecord::Migration[8.0]
  def change
    create_table :downloads do |t|
      t.integer :resource_id
      t.integer :file_id
      t.boolean :from_api
      t.boolean :as_zip
      t.string :ip
      t.text :user_agent
      t.integer :user_id

      t.timestamps
    end
  end
end
