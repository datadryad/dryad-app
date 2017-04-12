class CreateStashEngineUsers < ActiveRecord::Migration
  def change
    create_table :stash_engine_users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :uid
      t.string :provider
      t.string :oauth_token
      t.integer :institution_id

      t.timestamps null: false
    end
  end
end
