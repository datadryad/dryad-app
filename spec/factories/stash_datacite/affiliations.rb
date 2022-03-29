FactoryBot.define do

  factory :affiliation, class: StashDatacite::Affiliation do
    long_name { Faker::Lorem.unique.word }
    ror_id { create(:ror_org).ror_id }
  end

end
