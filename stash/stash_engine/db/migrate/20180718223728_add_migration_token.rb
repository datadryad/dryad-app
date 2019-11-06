class AddMigrationToken < ActiveRecord::Migration
  def change
    add_column :stash_engine_users, :migration_token, :string
    add_column :stash_engine_users, :old_dryad_email, :string
  end
end
