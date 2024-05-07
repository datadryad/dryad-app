FactoryBot.define do

  factory :funder, class: StashEngine::Funder do

    name { Faker::Company.name }
    ror_id { "https://ror.org/#{Faker::Number.number(digits: 7)}" }
    payment_plan { nil }
    enabled { true }
    covers_dpc { true }

  end

end
