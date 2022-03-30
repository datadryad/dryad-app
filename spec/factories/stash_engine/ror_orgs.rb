FactoryBot.define do

  factory :ror_org, class: StashEngine::RorOrg do

    name { Faker::Company.name }
    ror_id { "https://ror.org/#{Faker::Number.number(digits: 7)}" }
    # Don't default to a real country, because we don't want it to accidentally match when testing
    country { Faker::Address.country }

  end

end
