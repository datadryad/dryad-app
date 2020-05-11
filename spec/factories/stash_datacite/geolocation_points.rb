FactoryBot.define do

  factory :geolocation_point, class: StashDatacite::GeolocationPoint do
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
  end

end
