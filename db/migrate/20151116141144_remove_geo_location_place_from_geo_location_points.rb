class RemoveGeoLocationPlaceFromGeoLocationPoints < ActiveRecord::Migration
  def change
    change_table :dcs_geo_location_points do |t|
      t.remove :geo_location_place
    end
  end
end