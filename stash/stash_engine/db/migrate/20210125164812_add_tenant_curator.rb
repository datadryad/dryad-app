class AddTenantCurator < ActiveRecord::Migration[5.2]
  def change
    execute <<-SQL
      ALTER TABLE stash_engine_users MODIFY role ENUM('superuser', 'admin', 'user', 'tenant_curator')
    SQL
  end
end
