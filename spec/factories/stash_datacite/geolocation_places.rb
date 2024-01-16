# == Schema Information
#
# Table name: dcs_geo_location_places
#
#  id                 :integer          not null, primary key
#  geo_location_place :text(65535)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :geolocation_place, class: StashDatacite::GeolocationPlace do
    geo_location_place { Faker::Address.city }
  end
end
