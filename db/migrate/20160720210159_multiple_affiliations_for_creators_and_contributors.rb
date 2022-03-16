class MultipleAffiliationsForCreatorsAndContributors < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_affiliations_dcs_creators do |t|
      t.integer :affiliation_id
      t.integer :creator_id
      t.timestamps null: false
    end

    create_table :dcs_affiliations_dcs_contributors do |t|
      t.integer :affiliation_id
      t.integer :contributor_id
      t.timestamps null: false
    end
  end
end
