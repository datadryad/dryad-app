class ChangeTenantAbbrevToId < ActiveRecord::Migration
  def change
    remove_column :stash_engine_users, :tenant_abbrev
    add_column :stash_engine_users, :tenant_id, :string
    add_index :stash_engine_users, :tenant_id, length: { tenant_id: 50 }
  end
end
