class CreateStashEngineShares < ActiveRecord::Migration
  def change
    create_table :stash_engine_shares do |t|
      t.string :sharing_link
      t.datetime :expiration_date
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
