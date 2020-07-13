class AddOrcidIdToDcsCreators < ActiveRecord::Migration[4.2]
  def up
    add_column :dcs_creators, :orcid_id, :string
  end

  def down
    remove_column :dcs_creators, :orcid_id
  end
end
