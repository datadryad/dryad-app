class CreateDcsGeoLocationPlace < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_geo_location_places do |t|
      t.string :geo_location_place
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
