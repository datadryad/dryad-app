require 'datacite/mapping'

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
    def self.new_geolocation(place: nil, point: nil, box: nil, resource_id:)
      return unless place || point || box
      place_obj = nil
      point_obj = nil
      box_obj = nil
      place_obj = GeolocationPlace.create(geo_location_place: place) unless place.blank?
      point_obj = GeolocationPoint.create(latitude: point[0], longitude: point[1]) unless point.blank?
      unless box.blank? || box.flatten.length != 4
        sides = box.flatten.map{|i| i.try(:to_d)}
        s_lat = sides[0]
        n_lat = sides[2]
        s_lat, n_lat = n_lat, s_lat if s_lat > n_lat

        e_long = sides[1]
        w_long = sides[3]
        e_long, w_long = w_long, e_long if w_long > e_long

        box_obj = GeolocationBox.create(sw_latitude: s_lat, ne_latitude: n_lat,
                                        sw_longitude: w_long, ne_longitude: e_long)
      end
      Geolocation.create(place_id: place_obj.try(:id),
                         point_id: point_obj.try(:id),
                         box_id: box_obj.try(:id),
                         resource_id: resource_id)
    end

    def destroy_place
      pl = geolocation_place
      return unless pl
      pl.destroy
      self.place_id = nil
      destroy_if_empty
    end

    def destroy_point
      po = geolocation_point
      return unless po
      po.destroy
      self.point_id = nil
      destroy_if_empty
    end

    def destroy_box
      bo = geolocation_box
      return unless bo
      bo.destroy
      self.box_id = nil
      destroy_if_empty
    end

    #handles creating datacite mapping which might be nil or have other complexities
    def datacite_mapping_place
      try(:geolocation_place).try(:geo_location_place)
    end

    #handles creating datacite mapping which might be nil or have other complexities
    def datacite_mapping_point
      return nil unless geolocation_point
      return nil if geolocation_point.latitude.blank? || geolocation_point.longitude.blank?
      Datacite::Mapping::GeoLocationPoint.new(geolocation_point.latitude, geolocation_point.longitude)
    end

    #handles creating datacite mapping which might be nil or have other complexities
    def datacite_mapping_box
      return nil unless geolocation_box
      if geolocation_box.sw_latitude.blank? || geolocation_box.sw_longitude.blank?
        geolocation_box.ne_latitude.blank? || geolocation_box.ne_longitude.blank?
        return nil
      end
      Datacite::Mapping::GeoLocationBox.new(geolocation_box.sw_latitude, geolocation_box.sw_longitude,
                                            geolocation_box.ne_latitude, geolocation_box.ne_longitude)
    end

    private

    def destroy_if_empty
      if place_id.nil? && point_id.nil? && box_id.nil?
        destroy
      else
        save
      end
    end

    def set_geolocation_flag
      resource = StashDatacite.resource_class.where(id: resource_id).first
      return unless resource && resource.has_geolocation == false
      resource.has_geolocation = true
      resource.save!
    end

    def destroy_place_point_box
      geolocation_place.destroy unless place_id.nil?
      geolocation_point.destroy unless point_id.nil?
      geolocation_box.destroy unless box_id.nil?
    end
  end
end
