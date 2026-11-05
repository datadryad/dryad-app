FactoryBot.define do

  factory :funder, class: StashEngine::Funder do
    name { Faker::Company.name }
    ror_id { Faker::Pid.ror }
    enabled { true }

    after(:create) do |funder|
      create(:payment_configuration, partner: funder, payment_plan: nil)
    end
  end
end
