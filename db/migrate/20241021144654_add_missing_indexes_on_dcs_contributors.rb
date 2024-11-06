class AddMissingIndexesOnDcsContributors < ActiveRecord::Migration[7.0]
  def change
    add_index :dcs_contributors, :contributor_type
    add_index :dcs_contributors, :identifier_type
    add_index :dcs_contributors, :funder_order
  end
end
