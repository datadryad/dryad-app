FactoryBot.define do
  factory :geolocation_place, class: StashDatacite::GeolocationPlace do
    geo_location_place { Faker::Address.city }
  end
end
