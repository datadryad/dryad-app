class AddOrcidToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_users, :orcid, :string
  end
end
