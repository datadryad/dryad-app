# == Schema Information
#
# Table name: stash_engine_frictionless_reports
#
#  id              :bigint           not null, primary key
#  report          :text(4294967295)
#  status          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  generic_file_id :integer
#
# Indexes
#
#  index_stash_engine_frictionless_reports_on_generic_file_id  (generic_file_id)
#
# Foreign Keys
#
#  fk_rails_...  (generic_file_id => stash_engine_generic_files.id)
#
FactoryBot.define do

  factory :frictionless_report, class: StashEngine::FrictionlessReport do
    generic_file

    report { Faker::Json.shallow_json }
    status { %w[issues noissues checking error][rand(4)] }
  end
end
