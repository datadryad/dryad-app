class FixJoinTableNamesForAffiliations < ActiveRecord::Migration
  def change
    rename_table :dcs_affiliations_dcs_creators, :dcs_affiliations_creators
    rename_table :dcs_affiliations_dcs_contributors, :dcs_affiliations_contributors
  end
end
