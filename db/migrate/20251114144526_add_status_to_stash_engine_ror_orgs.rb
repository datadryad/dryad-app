class AddStatusToStashEngineRorOrgs < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_ror_orgs, :status, :integer, default: 0
    add_index :stash_engine_ror_orgs, :status
  end
end
