FactoryBot.define do

  factory :processor_result, class: StashEngine::ProcessorResult do
    resource

    processing_type { 'excel_to_csv' }
    parent_id { "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}" } # likely a file_id but depends on processing type
    completion_state { 'success' }
    message { Faker::Lorem.paragraph }
    structured_info { Faker::Json.shallow_json }

  end
end