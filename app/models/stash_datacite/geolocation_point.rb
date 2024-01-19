# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_geo_location_points
#
#  id         :integer          not null, primary key
#  latitude   :decimal(10, 6)
#  longitude  :decimal(10, 6)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module StashDatacite
  class GeolocationPoint < ApplicationRecord
    self.table_name = 'dcs_geo_location_points'
    has_one :geolocation, class_name: 'StashDatacite::Geolocation', foreign_key: 'point_id', dependent: :nullify

    scope :from_resource_id, ->(resource_id) {
      joins(:geolocation)
        .where('dcs_geo_locations.resource_id = ?', resource_id)
    }

    scope :only_geo_points, ->(resource_id) {
      joins(:geolocation)
        .where('dcs_geo_locations.resource_id = ?', resource_id)
        .where('dcs_geo_locations.place_id IS NULL AND dcs_geo_locations.box_id IS NULL')
    }

    # returns a bounding box string for use with Javascript
    def bounding_box_str
      return nil unless longitude && latitude

      "#{longitude} #{latitude} #{longitude} #{latitude}"
    end
  end
end
