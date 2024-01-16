# == Schema Information
#
# Table name: stash_engine_frictionless_reports
#
#  id              :bigint           not null, primary key
#  report          :text(4294967295)
#  generic_file_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  status          :string
#
FactoryBot.define do

  factory :frictionless_report, class: StashEngine::FrictionlessReport do
    generic_file

    report { Faker::Json.shallow_json }
    status { %w[issues noissues checking error][rand(4)] }
  end
end
