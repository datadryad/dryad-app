require 'http'

# needs to include CC-BY which isn't OSI approved
class UpdateStashEngineSoftwareLicenses < ActiveRecord::Migration[4.2]
  def up
    # remove licenses and repopulate them from larger list
    execute 'DELETE FROM stash_engine_software_licenses'
    populate_table_from_spdx unless Rails.env == 'test'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def populate_table_from_spdx
    http = HTTP.get('https://raw.githubusercontent.com/spdx/license-list-data/master/json/licenses.json')
    if http.status.success?
      json = JSON.parse(http.body.to_s)
      json['licenses'].each do |license|
        # the list is ridiculously huge without limiting to OsiApproved and not deprecated items
        if license['isDeprecatedLicenseId'] == false
          StashEngine::SoftwareLicense.create(name: license['name'], identifier: license['licenseId'],
                                              details_url: license['detailsUrl'])
        end
      end
    end
  rescue HTTP::Error
    # just ignore and you'll need to fix manually
    puts "WARNING, couldn't get license list from SPDX on github"
  end
end
