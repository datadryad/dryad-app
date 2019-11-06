class RemoveInstitutionIdFromUsers < ActiveRecord::Migration
  def change
    remove_column :stash_engine_users, :institution_id, :integer
    add_column :stash_engine_users, :tenant_abbrev, :string
    add_index :stash_engine_users, :tenant_abbrev, length: { tenant_abbrev: 50 }
  end
end
