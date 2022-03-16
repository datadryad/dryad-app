class CreateDcsGeoLocationBoxes < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_geo_location_boxes do |t|
      t.float :sw_latitude
      t.float :ne_latitude
      t.float :sw_longitude
      t.float :ne_longitude
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
