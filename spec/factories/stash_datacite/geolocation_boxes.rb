FactoryBot.define do
  factory :geolocation_box, class: StashDatacite::GeolocationBox do
    sw_latitude { Faker::Address.latitude }
    ne_latitude { Faker::Address.latitude }
    sw_longitude { Faker::Address.longitude }
    ne_longitude { Faker::Address.longitude }
  end
end
