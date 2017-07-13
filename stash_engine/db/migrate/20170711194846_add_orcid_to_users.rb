class AddOrcidToUsers < ActiveRecord::Migration
  def change
    add_column :stash_engine_users, :orcid, :string
  end
end
