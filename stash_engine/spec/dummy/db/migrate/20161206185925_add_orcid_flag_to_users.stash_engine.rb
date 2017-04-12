# This migration comes from stash_engine (originally 20160308164307)
class AddOrcidFlagToUsers < ActiveRecord::Migration
  def up
    add_column :stash_engine_users, :orcid, :boolean, :default => false
  end

  def down
    remove_column :stash_engine_resources, :orcid
  end
end
