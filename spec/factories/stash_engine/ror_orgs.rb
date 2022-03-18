FactoryBot.define do

  factory :ror_org, class: StashEngine::RorOrg do

    name { Faker::Company.name }
    ror_id { "https://ror.org/#{Faker::Number.number(digits: 4)}" }
    # Don't default to a real country, because we don't want it to accidentally match when testing
    country { 'The Undiscovered Country' }

  end

end
