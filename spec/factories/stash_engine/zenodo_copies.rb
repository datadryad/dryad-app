FactoryBot.define do

  factory :zenodo_copy, class: StashEngine::ZenodoCopy do
    resource

    state { 'enqueued' }
    deposition_id { Faker::Number.number(digits: 5) }
    error_info { nil }
    identifier_id { nil }
    copy_type { 'data' }
  end
end
