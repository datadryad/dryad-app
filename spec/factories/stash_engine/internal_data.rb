# rubocop:disable Metrics/BlockLength
FactoryBot.define do

  factory :internal_datum, class: StashEngine::InternalDatum do
    identifier_id { Faker::Number.number(3).to_i }
    data_type { 'publicationISSN' }
    value { "#{Faker::Number.number(4)}-#{Faker::Number.number(4)}" }
  end
end
# rubocop:enable Metrics/BlockLength