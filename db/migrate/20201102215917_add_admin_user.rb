class AddAdminUser < ActiveRecord::Migration[5.2]
  def up
    execute "INSERT IGNORE INTO stash_engine_users (id, first_name, last_name, role, created_at, updated_at) VALUES (0, 'Dryad', 'System', 'user', '2020-01-01', '2020-01-01')"
  end

  def down
    execute "DELETE FROM stash_engine_users WHERE id = 0"
  end
end
