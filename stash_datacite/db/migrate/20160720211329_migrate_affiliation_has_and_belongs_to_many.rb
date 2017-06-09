class MigrateAffiliationHasAndBelongsToMany < ActiveRecord::Migration
  def change
    StashDatacite::Creator.where('affiliation_id IS NOT NULL').each do |c|
      # we shouldn't need to worry about sanitization since theres are only integers in current db for these fields
      next if c.affiliation_id.blank?
      sql = 'INSERT INTO dcs_affiliations_creators (affiliation_id, creator_id, ' \
            "created_at, updated_at) VALUES(#{c.affiliation_id}, #{c.id}, NOW(), NOW())"
      ret = ActiveRecord::Base.connection.insert(sql)
    end

    StashDatacite::Contributor.where('affiliation_id IS NOT NULL').each do |c|
      # we shouldn't need to worry about sanitization since theres are only integers in current db for these fields
      next if c.affiliation_id.blank?
      sql = 'INSERT INTO dcs_affiliations_contributors (affiliation_id, contributor_id, ' \
            "created_at, updated_at) VALUES(#{c.affiliation_id}, #{c.id}, NOW(), NOW())"
      ret = ActiveRecord::Base.connection.insert(sql)
    end

    remove_column :dcs_creators, :affiliation_id
    remove_column :dcs_contributors, :affiliation_id
  end
end
