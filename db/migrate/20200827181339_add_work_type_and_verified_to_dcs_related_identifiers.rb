class AddWorkTypeAndVerifiedToDcsRelatedIdentifiers < ActiveRecord::Migration[5.1]
  def change
    # in the model this is an enum [:undefined, :article, :dataset, :preprint, :software, :supplemental_information]
    add_column :dcs_related_identifiers, :work_type, :integer, default: 0 # undefined
    add_column :dcs_related_identifiers, :verified, :boolean, default: false
  end
end
