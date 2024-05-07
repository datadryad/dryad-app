class RemoveUserRole < ActiveRecord::Migration[6.1]
  def change
    remove_column :stash_engine_users, :role, :string
  end
end
