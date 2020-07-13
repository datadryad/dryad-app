class ChangeColumnTypeInGelocationBoxes < ActiveRecord::Migration[4.2]
  def up
    change_column :dcs_geo_location_boxes, :sw_latitude, :decimal, precision: 10, scale: 6
    change_column :dcs_geo_location_boxes, :sw_longitude, :decimal, precision: 10, scale: 6
    change_column :dcs_geo_location_boxes, :ne_latitude, :decimal, precision: 10, scale: 6
    change_column :dcs_geo_location_boxes, :ne_longitude, :decimal, precision: 10, scale: 6
  end

  def down
    change_column :dcs_geo_location_boxes, :sw_latitude, :float
    change_column :dcs_geo_location_boxes, :sw_longitude, :float
    change_column :dcs_geo_location_boxes, :ne_latitude, :float
    change_column :dcs_geo_location_boxes, :ne_longitude, :float
  end
end
