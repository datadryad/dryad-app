class AddLimitedCuratorRoleToUser < ActiveRecord::Migration[5.2]
  def change
    execute <<-SQL
      ALTER TABLE stash_engine_users MODIFY role ENUM('superuser', 'curator', 'admin', 'user', 'tenant_curator', 
        'limited_curator')
    SQL
  end
end
