# This migration comes from stash_engine (originally 20160129011614)
class RemoveInstitutionIdFromUsers < ActiveRecord::Migration
  def change
    remove_column :stash_engine_users, :institution_id, :integer
    add_column :stash_engine_users, :tenant_abbrev, :string
    add_index :stash_engine_users, :tenant_abbrev
  end
end
