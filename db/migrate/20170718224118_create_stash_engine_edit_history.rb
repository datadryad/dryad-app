class CreateStashEngineEditHistory < ActiveRecord::Migration[4.2]
  def change
    create_table :stash_engine_edit_histories do |t|
      t.integer :resource_id
      t.integer :identifier_id
      t.integer :user_id
      t.text :user_comment

      t.index :resource_id
      t.index :identifier_id
      t.index :user_id

      t.timestamps null: false
    end
  end
end
