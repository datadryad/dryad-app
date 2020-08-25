class SimplifyLoginFields < ActiveRecord::Migration[4.2]
  def change
    remove_column :stash_engine_users, :uid, :string
    remove_column :stash_engine_users, :provider, :string
    remove_column :stash_engine_users, :oauth_token, :string
  end
end
