class RenameAffliationToAffiliation < ActiveRecord::Migration[4.2]
  def change
    rename_column :dcs_contributors, :affliation_id, :affiliation_id
    rename_column :dcs_creators, :affliation_id, :affiliation_id
    rename_table :dcs_affliations, :dcs_affiliations
  end
end
