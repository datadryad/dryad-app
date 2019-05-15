FactoryBot.define do

  factory :affiliation, class: StashDatacite::Affiliation do
    long_name { Faker::Lorem.unique.word }
  end

end
