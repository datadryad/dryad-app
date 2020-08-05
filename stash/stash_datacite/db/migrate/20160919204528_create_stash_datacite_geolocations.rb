class CreateStashDataciteGeolocations < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_geo_locations do |t|
      t.integer :place_id
      t.integer :point_id
      t.integer :box_id

      t.timestamps null: false
    end
  end
end
