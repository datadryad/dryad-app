class AddColumnsInGeolocationPlaces < ActiveRecord::Migration
  def up
    add_column :dcs_geo_location_places, :latitude, :decimal, precision: 10, scale: 6
    add_column :dcs_geo_location_places, :longitude, :decimal, precision: 10, scale: 6
  end

  def down
    remove_column :dcs_geo_location_places, :latitude
    remove_column :dcs_geo_location_places, :longitude
  end
end
