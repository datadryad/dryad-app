class CreateStashEngineEmbargoes < ActiveRecord::Migration[4.2]
  def change
    create_table :stash_engine_embargoes do |t|
      t.datetime :end_date
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
