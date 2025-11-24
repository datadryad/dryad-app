class AddAwardVerifiedToDcsContributors < ActiveRecord::Migration[8.0]
  def change
    add_column :dcs_contributors, :award_verified, :boolean, default: false
    add_index :dcs_contributors, :award_verified
  end
end
