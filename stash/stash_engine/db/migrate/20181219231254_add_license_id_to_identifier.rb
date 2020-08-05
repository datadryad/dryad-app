class AddLicenseIdToIdentifier < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_identifiers, :license_id, :string, default: 'cc0', after: :latest_resource_id
    add_index :stash_engine_identifiers, :license_id
  end
end
