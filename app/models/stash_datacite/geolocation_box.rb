# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_geo_location_boxes
#
#  id           :integer          not null, primary key
#  sw_latitude  :decimal(10, 6)
#  ne_latitude  :decimal(10, 6)
#  sw_longitude :decimal(10, 6)
#  ne_longitude :decimal(10, 6)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
module StashDatacite
  class GeolocationBox < ApplicationRecord
    self.table_name = 'dcs_geo_location_boxes'
    has_one :geolocation, class_name: 'StashDatacite::Geolocation', foreign_key: 'box_id', dependent: :nullify

    scope :from_resource_id, ->(resource_id) {
      joins(:geolocation)
        .where('dcs_geo_locations.resource_id = ?', resource_id)
    }

    scope :only_geo_bbox, ->(resource_id) {
                            joins(:geolocation)
                              .where('dcs_geo_locations.resource_id = ?', resource_id)
                              .where('dcs_geo_locations.place_id IS NULL AND dcs_geo_locations.point_id IS NULL')
                          }

    # returns a bounding box string for use with Javascript
    def bounding_box_str
      return nil unless sw_longitude && sw_latitude && ne_longitude && ne_latitude

      "#{sw_longitude} #{sw_latitude} #{ne_longitude} #{ne_latitude}"
    end
  end
end
