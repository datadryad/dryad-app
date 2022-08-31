class CreateApiTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :stash_engine_api_tokens do |t|
      t.string :app_id
      t.string :secret
      t.string :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
