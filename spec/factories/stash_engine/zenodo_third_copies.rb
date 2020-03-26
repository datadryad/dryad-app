FactoryBot.define do

  factory :zenodo_third_copy, class: StashEngine::ZenodoThirdCopy do
    resource

    state { 'enqueued' }
    deposition_id { Faker::Number.number(digits: 5) }
    error_info { nil }
    identifier_id { nil }
  end
end
