# == Schema Information
#
# Table name: dcs_geo_locations
#
#  id          :integer          not null, primary key
#  place_id    :integer
#  point_id    :integer
#  box_id      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
FactoryBot.define do
  factory :geolocation, class: StashDatacite::Geolocation do
    place_id { nil }
    point_id { nil }
    box_id { nil }
  end
end
