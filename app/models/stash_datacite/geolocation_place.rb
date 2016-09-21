module StashDatacite
  class GeolocationPlace < ActiveRecord::Base
    self.table_name = 'dcs_geo_location_places'
    has_one :geolocation, class_name: 'StashDatacite::Geolocation', foreign_key: 'place_id', dependent: :nullify

    scope :from_resource_id, ->(resource_id) { joins(:geolocation).
        where('dcs_geo_locations.resource_id = ?', resource_id)}

    #returns a bounding box string for use with Javascript
    def bounding_box_str
      return nil unless geolocation
      return geolocation.geolocation_box.bounding_box_str if geolocation.geolocation_box
      return geolocation.geolocation_point.bounding_box_str if geolocation.geolocation_point
      nil
    end
  end
end
