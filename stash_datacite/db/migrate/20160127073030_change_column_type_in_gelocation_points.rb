class ChangeColumnTypeInGelocationPoints < ActiveRecord::Migration
  def up
    change_column :dcs_geo_location_points, :latitude, :decimal, precision: 10, scale: 6
    change_column :dcs_geo_location_points, :longitude, :decimal, precision: 10, scale: 6
  end

  def down
    change_column :dcs_geo_location_points, :latitude, :float
    change_column :dcs_geo_location_points, :longitude, :float
  end
end
