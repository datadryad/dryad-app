# This migration comes from stash_datacite (originally 20160919221509)
class AddResourceIdToGeolocation < ActiveRecord::Migration
  def change
    add_column :dcs_geo_locations, :resource_id, :integer
    add_index :dcs_geo_locations, :resource_id
  end
end
