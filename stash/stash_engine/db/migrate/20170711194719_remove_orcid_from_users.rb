class RemoveOrcidFromUsers < ActiveRecord::Migration
  def change
    remove_column :stash_engine_users, :orcid, :boolean
  end
end
