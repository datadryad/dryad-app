class RemoveOrcidFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :stash_engine_users, :orcid, :boolean
  end
end
