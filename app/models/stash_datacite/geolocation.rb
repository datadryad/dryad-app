module StashDatacite
  class Geolocation < ActiveRecord::Base
    self.table_name = 'dcs_geo_locations'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :geolocation_place, class_name: 'StashDatacite::GeolocationPlace', foreign_key: 'place_id'
    belongs_to :geolocation_point, class_name: 'StashDatacite::GeolocationPoint', foreign_key: 'point_id'
    belongs_to :geolocation_box, class_name: 'StashDatacite::GeolocationBox', foreign_key: 'box_id'

    amoeba do
      enable
    end

    after_save :set_geolocation_flag

    after_destroy :destroy_place_point_box

    # a simple convenience method for creating datacite geolocation full record
    # place is string, point is [lat long] and box is [[ lat, long], [lat, long]] (or [lat, long, lat, long] )
    def self.new_geolocation(place: nil, point: nil, box: nil, resource_id: resource_id)
      return unless place || point || box
      place_obj, point_obj, box_obj = nil, nil, nil
      place_obj = GeolocationPlace.create(geo_location_place: place) unless place.blank?
      point_obj = GeolocationPoint.create(latitude: point[0], longitude: point[1]) unless point.blank?
      unless box.blank? || box.flatten.length != 4
        sides = box.flatten
        s_lat, n_lat = sides[0], sides[2]
        s_lat, n_lat = n_lat, s_lat if s_lat > n_lat

        e_long, w_long = sides[1], sides[3]
        e_long, w_long = w_long, e_long if w_long > e_long

        box_obj = GeolocationBox.create(sw_latitude: s_lat, ne_latitude: n_lat, sw_longitude: w_long, ne_longitude: e_long)
      end
      Geolocation.create(place_id: place_obj.try(:id), point_id: point_obj.try(:id), box_id: box_obj.try(:id),
                         resource_id: resource_id)
    end

    private

    def set_geolocation_flag
      resource = StashDatacite.resource_class.where(id: resource_id).first
      return unless resource && resource.has_geolocation == false
      resource.has_geolocation = true
      resource.save!
    end

    def destroy_place_point_box
      geolocation_place.destroy
      geolocation_point.destroy
      geolocation_box.destroy
    end

  end
end
