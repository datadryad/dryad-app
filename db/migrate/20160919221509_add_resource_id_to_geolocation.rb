class AddResourceIdToGeolocation < ActiveRecord::Migration[4.2]
  def change
    add_column :dcs_geo_locations, :resource_id, :integer
    add_index :dcs_geo_locations, :resource_id
  end
end
