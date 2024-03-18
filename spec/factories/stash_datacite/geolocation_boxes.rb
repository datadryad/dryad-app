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
FactoryBot.define do
  factory :geolocation_box, class: StashDatacite::GeolocationBox do
    sw_latitude { Faker::Address.latitude }
    ne_latitude { Faker::Address.latitude }
    sw_longitude { Faker::Address.longitude }
    ne_longitude { Faker::Address.longitude }
  end
end
