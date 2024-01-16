# == Schema Information
#
# Table name: stash_engine_internal_data
#
#  id            :integer          not null, primary key
#  identifier_id :integer
#  data_type     :string(191)
#  value         :string(191)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
FactoryBot.define do

  factory :internal_datum, class: StashEngine::InternalDatum do
    identifier_id { Faker::Number.number(digits: 3).to_i }
    data_type { 'publicationISSN' }
    value { "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}" }
  end
end
