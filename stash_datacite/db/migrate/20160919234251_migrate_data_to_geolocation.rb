class MigrateDataToGeolocation < ActiveRecord::Migration
  def self.up
    # move places into new Geolocation table
    StashDatacite::GeolocationPlace.where('resource_id IS NOT NULL').each do |place|
      point = nil
      point = StashDatacite::GeolocationPoint.create(latitude: place.latitude, longitude: place.longitude) if place.latitude && place.longitude
      StashDatacite::Geolocation.create(resource_id: place.resource_id, place_id: place.id, point_id: point.try(:id))
    end

    # move points into Geolocation table
    StashDatacite::GeolocationPoint.where('resource_id IS NOT NULL').each do |point|
      StashDatacite::Geolocation.create(resource_id: point.resource_id, point_id: point.id)
    end

    # move boxes into Geolocation table
    StashDatacite::GeolocationBox.where('resource_id IS NOT NULL').each do |box|
      StashDatacite::Geolocation.create(resource_id: box.resource_id, box_id: box.id)
    end

    remove_column :dcs_geo_location_places, :resource_id
    remove_column :dcs_geo_location_places, :latitude
    remove_column :dcs_geo_location_places, :longitude
    remove_column :dcs_geo_location_points, :resource_id
    remove_column :dcs_geo_location_boxes, :resource_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
