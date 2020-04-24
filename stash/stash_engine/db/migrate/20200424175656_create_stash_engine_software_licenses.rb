require 'http'

class CreateStashEngineSoftwareLicenses < ActiveRecord::Migration
  def up
    create_table :stash_engine_software_licenses do |t|
      t.string :name
      t.string :identifier
      t.string :details_url

      t.timestamps null: false

      t.index :identifier, unique: true
    end

    add_column :stash_engine_identifiers, :software_license_id, :integer
    add_index :stash_engine_identifiers, :software_license_id

    populate_table_from_spdx unless Rails.env == 'test'
  end

  def down
    drop_table :stash_engine_software_licenses
    remove_column :stash_engine_identifiers, :software_license_id, :integer
  end

  def populate_table_from_spdx
    http = HTTP.get('https://raw.githubusercontent.com/spdx/license-list-data/master/json/licenses.json')
    if http.status.success?
      json = JSON.parse(http.body.to_s)
      json['licenses'].each do |license|
        StashEngine::SoftwareLicense.create(name: license['name'], identifier: license['licenseId'], details_url: license['detailsUrl'])
      end
    end
  rescue HTTP::Error
    # just ignore and you'll need to fix manually
    puts "WARNING, couldn't get license list from SPDX on github"
  end
end
