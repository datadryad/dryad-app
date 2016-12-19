# This migration comes from stash_datacite (originally 20160225185754)
class AddOrcidIdToDcsCreators < ActiveRecord::Migration
  def up
    add_column :dcs_creators, :orcid_id, :string
  end

  def down
    remove_column :dcs_creators, :orcid_id
  end
end
