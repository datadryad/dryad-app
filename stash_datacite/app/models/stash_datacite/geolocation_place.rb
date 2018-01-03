# frozen_string_literal: true

module StashDatacite
  class GeolocationPlace < ActiveRecord::Base
    self.table_name = 'dcs_geo_location_places'
    has_one :geolocation, class_name: 'StashDatacite::Geolocation', foreign_key: 'place_id', dependent: :nullify

    scope :from_resource_id, ->(resource_id) {
      joins(:geolocation)
        .where('dcs_geo_locations.resource_id = ?', resource_id)
    }

    def self.geo_places(resource_id)
      GeolocationPlace.from_resource_id(resource_id).map do |place|
        geo_hash = { geolocation_place: place.geo_location_place }
        point = (loc = place.geolocation) && loc.geolocation_point
        point ? geo_hash.merge(latitude: point.latitude, longitude: point.longitude) : geo_hash
      end
    end

    def bounding_box_str
      return nil unless geolocation
      return geolocation.geolocation_box.bounding_box_str if geolocation.geolocation_box
      return geolocation.geolocation_point.bounding_box_str if geolocation.geolocation_point
      nil
    end
  end
end
