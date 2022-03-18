FactoryBot.define do

  factory :ror_org, class: StashEngine::RorOrg do

    name { Faker::Company.name }
    ror_id { "https://ror.org/#{Faker::Number.number(digits: 4)}" }
    country { 'The Undiscovered Country' }

  end

end
