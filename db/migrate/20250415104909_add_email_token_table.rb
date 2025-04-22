class AddEmailTokenTable < ActiveRecord::Migration[8.0]
  def change
    create_table :stash_engine_email_tokens do |t|
      t.string :tenant_id
      t.integer :user_id
      t.string :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
