FactoryBot.define do

  factory :internal_datum, class: StashEngine::InternalDatum do
    identifier_id { Faker::Number.number(digits: 3).to_i }
    data_type { 'publicationISSN' }
    value { "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}" }
  end
end
