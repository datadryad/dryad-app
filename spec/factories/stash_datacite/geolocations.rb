# == Schema Information
#
# Table name: dcs_geo_locations
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  box_id      :integer
#  place_id    :integer
#  point_id    :integer
#  resource_id :integer
#
# Indexes
#
#  index_dcs_geo_locations_on_box_id       (box_id)
#  index_dcs_geo_locations_on_place_id     (place_id)
#  index_dcs_geo_locations_on_point_id     (point_id)
#  index_dcs_geo_locations_on_resource_id  (resource_id)
#
FactoryBot.define do
  factory :geolocation, class: StashDatacite::Geolocation do
    place_id { nil }
    point_id { nil }
    box_id { nil }
  end
end
