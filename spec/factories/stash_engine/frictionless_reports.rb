# == Schema Information
#
# Table name: stash_engine_frictionless_reports
#
#  id              :integer          not null, primary key
#  report          :text(4294967295)
#  status          :string
#  created_at      :datetime
#  updated_at      :datetime
#  generic_file_id :integer
#
FactoryBot.define do

  factory :frictionless_report, class: StashEngine::FrictionlessReport do
    generic_file

    report { Faker::Json.shallow_json }
    status { %w[issues noissues checking error][rand(4)] }
  end
end
