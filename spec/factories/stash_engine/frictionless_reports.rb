FactoryBot.define do

  factory :frictionless_report, class: StashEngine::FrictionlessReport do
    generic_file

    report { Faker::Json.shallow_json }
    status { %w[issues noissues checking error][rand(4)] }
  end
end
