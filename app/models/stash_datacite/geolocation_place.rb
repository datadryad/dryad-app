module StashDatacite
  class GeolocationPlace < ActiveRecord::Base
    self.table_name = 'dcs_geo_location_places'
    has_one :geolocation, class_name: 'StashDatacite::Geolocation', foreign_key: 'place_id', dependent: :nullify

    scope :from_resource_id, ->(resource_id) {
      joins(:geolocation)
        .where('dcs_geo_locations.resource_id = ?', resource_id)
    }

    def self.geo_places(resource_id)
      places = []
      geo_places = GeolocationPlace.from_resource_id(resource_id)
      unless geo_places.blank?
        geo_places.each do |geo_pl|
          coordinates = geo_pl.geo_place_coordinates(resource_id)
          geo_hash = { geolocation_place: geo_pl.geo_location_place, latitude: coordinates[0], longitude: coordinates[1], id: geo_pl.id }
          places << geo_hash
        end
      end
      places
    end

    def geo_place_coordinates(_resource_id)
      if geolocation.geolocation_point.present?
        latitude = geolocation.geolocation_point.latitude
        longitude = geolocation.geolocation_point.longitude
        return [latitude, longitude]
      else
        []
      end
    end

    # def geo_place_boxes(resource_id)
    #   GeolocationBox.select('dcs_geo_location_boxes.sw_longitude, dcs_geo_location_boxes.sw_latitude, dcs_geo_location_boxes.ne_longitude, dcs_geo_location_boxes.ne_latitude')
    #                 .joins(:geolocation)
    #                 .where('dcs_geo_locations.place_id = ?', self.id)
    #                 .where('dcs_geo_locations.resource_id = ?', resource_id).first
    # end

    #returns a bounding box string for use with Javascript
    def bounding_box_str
      return nil unless geolocation
      return geolocation.geolocation_box.bounding_box_str if geolocation.geolocation_box
      return geolocation.geolocation_point.bounding_box_str if geolocation.geolocation_point
      nil
    end
  end
end
