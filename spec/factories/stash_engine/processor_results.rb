# == Schema Information
#
# Table name: stash_engine_processor_results
#
#  id               :bigint           not null, primary key
#  resource_id      :integer
#  processing_type  :integer
#  parent_id        :integer
#  completion_state :integer
#  message          :text(16777215)
#  structured_info  :text(4294967295)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
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
