class MigrateAffiliationHasAndBelongsToMany < ActiveRecord::Migration
  def change
    execute <<-SQL
      INSERT INTO dcs_affiliations_creators (affiliation_id, creator_id, created_at, updated_at)
           SELECT dcs_creators.affiliation_id, dcs_creators.id, NOW(), NOW()
             FROM dcs_creators;
    SQL

    execute <<-SQL
      INSERT INTO dcs_affiliations_contributors (affiliation_id, contributor_id, created_at, updated_at)
           SELECT dcs_contributors.affiliation_id, dcs_contributors.id, NOW(), NOW()
             FROM dcs_contributors;
    SQL

    remove_column :dcs_creators, :affiliation_id
    remove_column :dcs_contributors, :affiliation_id
  end
end
