class AddAuthDate < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_users, :tenant_auth_date, :datetime
  end
end
