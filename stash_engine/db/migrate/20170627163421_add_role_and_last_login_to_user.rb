class AddRoleAndLastLoginToUser < ActiveRecord::Migration
  def up
    add_column :stash_engine_users, :last_login, :datetime
    connection.execute('UPDATE stash_engine_users SET last_login = updated_at')
    add_column :stash_engine_users, :role, "ENUM('superuser', 'admin', 'user')", default: 'user'
  end

  def down
    remove_column :stash_engine_users, :last_login
    remove_column :stash_engine_users, :role
  end
end
