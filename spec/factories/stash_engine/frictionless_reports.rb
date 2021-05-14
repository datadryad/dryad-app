FactoryBot.define do

  factory :frictionless_report, class: StashEngine::FrictionlessReport do
    generic_file

    report { Faker::Json.shallow_json }
  end
end
