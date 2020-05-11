FactoryBot.define do
  factory :geolocation, class: StashDatacite::Geolocation do
    place_id { nil }
    point_id { nil }
    box_id { nil }
  end
end
