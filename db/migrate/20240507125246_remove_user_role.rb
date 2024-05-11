class RemoveUserRole < ActiveRecord::Migration[6.1]
  def change
    remove_column :stash_engine_users, :role, "ENUM('superuser', 'admin', 'user')", default: 'user'
  end
end
