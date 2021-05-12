# frozen_string_literal: true

require 'datacite/mapping'

module StashDatacite
  class Geolocation < ApplicationRecord
    self.table_name = 'dcs_geo_locations'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
    belongs_to :geolocation_place, class_name: 'StashDatacite::GeolocationPlace', foreign_key: 'place_id', optional: true
    belongs_to :geolocation_point, class_name: 'StashDatacite::GeolocationPoint', foreign_key: 'point_id', optional: true
    belongs_to :geolocation_box, class_name: 'StashDatacite::GeolocationBox', foreign_key: 'box_id', optional: true

    amoeba do
      enable
      customize(->(_orig_geo, new_geo) do
        # this duplicates any non-null associated places, points, boxes and associtaes them with the new record
        items = { :place_id= => :geolocation_place, :point_id= => :geolocation_point, :box_id= => :geolocation_box }
        items.each_pair do |my_id, my_association|
          next unless new_geo.send(my_association) # if it's associated, duplicate it and reset id to new one

          newone = new_geo.send(my_association).dup
          newone.save
          new_geo.send(my_id, newone.id) # set the id for duplicated item in the geolocation record
        end
      end)
    end

    after_save :set_geolocation_flag

    after_destroy :destroy_place_point_box

    # a simple convenience method for creating datacite geolocation full record
    # place is string, point is [lat long] and box is [[ lat, long], [lat, long]] (or [lat, long, lat, long] )
    def self.new_geolocation(resource_id:, place: nil, point: nil, box: nil)
      return unless place || point || box

      Geolocation.create(
        place_id: place_id_from(place),
        point_id: point_id_from(point),
        box_id: box_id_from(box),
        resource_id: resource_id
      )
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

    # handles creating datacite mapping which might be nil or have other complexities
    def datacite_mapping_place
      try(:geolocation_place).try(:geo_location_place)
    end

    # handles creating datacite mapping which might be nil or have other complexities
    def datacite_mapping_point
      return nil unless geolocation_point
      return nil if geolocation_point.latitude.blank? || geolocation_point.longitude.blank?

      Datacite::Mapping::GeoLocationPoint.new(geolocation_point.latitude, geolocation_point.longitude)
    end

    # handles creating datacite mapping which might be nil or have other complexities
    def datacite_mapping_box
      return nil unless geolocation_box

      coords = [
        geolocation_box.sw_latitude,
        geolocation_box.sw_longitude,
        geolocation_box.ne_latitude,
        geolocation_box.ne_longitude
      ]
      return if coords.any?(&:blank?)

      Datacite::Mapping::GeoLocationBox.new(*coords)
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
      resource = StashEngine::Resource.where(id: resource_id).first
      return unless resource && resource.has_geolocation == false

      resource.has_geolocation = true
      resource.save!
    end

    def destroy_place_point_box
      GeolocationPlace.destroy(place_id) unless place_id.nil? || GeolocationPlace.where(id: place_id).count < 1
      GeolocationPoint.destroy(point_id) unless point_id.nil? || GeolocationPoint.where(id: point_id).count < 1
      GeolocationBox.destroy(box_id) unless box_id.nil? || GeolocationBox.where(id: box_id).count < 1
    end

    def self.place_id_from(place)
      return if place.blank?

      GeolocationPlace.create(geo_location_place: place).id
    end
    private_class_method :place_id_from

    def self.point_id_from(point)
      return if point.blank?

      latitude = point[0].try(:to_d)
      longitude = point[1].try(:to_d)
      GeolocationPoint.create(latitude: latitude, longitude: longitude).id
    end
    private_class_method :point_id_from

    def self.box_id_from(box)
      return if box.blank? || box.flatten.length != 4

      sides = box.flatten.map { |i| i.try(:to_d) }
      n_lat, e_long, s_lat, w_long = coords_from(sides)
      GeolocationBox.create(
        sw_latitude: s_lat,
        ne_latitude: n_lat,
        sw_longitude: w_long,
        ne_longitude: e_long
      ).id
    end
    private_class_method :box_id_from

    def self.coords_from(sides)
      s_lat = sides[0]
      e_long = sides[1]
      n_lat = sides[2]
      w_long = sides[3]
      s_lat, n_lat = n_lat, s_lat if s_lat > n_lat
      e_long, w_long = w_long, e_long if w_long > e_long

      [n_lat, e_long, s_lat, w_long]
    end
    private_class_method :coords_from
  end
end
