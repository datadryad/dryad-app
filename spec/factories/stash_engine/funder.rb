FactoryBot.define do

  factory :funder, class: StashEngine::Funder do
    name { Faker::Company.name }
    ror_id { "https://ror.org/#{Faker::Number.number(digits: 7)}" }
    enabled { true }
  end
end
