class AddOrcidFlagToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :stash_engine_users, :orcid, :boolean, default: false
  end

  def down
    remove_column :stash_engine_resources, :orcid
  end
end
