# == Schema Information
#
# Table name: stash_engine_sensitive_data_reports
#
#  id              :bigint           not null, primary key
#  report          :text(4294967295)
#  generic_file_id :integer
#  status          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_stash_engine_sensitive_data_reports_on_generic_file_id  (generic_file_id)
#
# Foreign Keys
#
#  fk_rails_...  (generic_file_id => stash_engine_generic_files.id)
#
FactoryBot.define do

  factory :sensitive_data_report, class: StashEngine::SensitiveDataReport do
    generic_file

    report { Faker::Json.shallow_json }
    status { %w[issues noissues checking error][rand(4)] }
  end
end
