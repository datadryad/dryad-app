class DropOrcidIdFromDcsCreators < ActiveRecord::Migration
  def change
    StashDatacite::Creator.where("orcid_id IS NOT NULL").each do |c|
      name_id = StashDatacite::NameIdentifier.find_or_create_by(name_identifier: c.orcid_id) do |ni|
        ni.name_identifier_scheme = 'ORCID'
        ni.scheme_URI = 'http://orcid.org'
      end
      c.name_identifier_id = name_id.id
      c.save!
    end
    remove_column :dcs_creators, :orcid_id
  end
end
