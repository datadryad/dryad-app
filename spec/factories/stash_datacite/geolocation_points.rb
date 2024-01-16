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
FactoryBot.define do

  factory :geolocation_point, class: StashDatacite::GeolocationPoint do
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
  end

end
