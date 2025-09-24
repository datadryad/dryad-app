FactoryBot.define do

  factory :funder, class: StashEngine::Funder do
    name { Faker::Company.name }
    ror_id { "https://ror.org/#{Faker::Number.number(digits: 7)}" }
    enabled { true }

    after(:create) do |funder|
      create(:payment_configuration, partner: funder, payment_plan: nil, covers_dpc: true)
    end
  end
end
