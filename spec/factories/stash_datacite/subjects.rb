# == Schema Information
#
# Table name: dcs_subjects
#
#  id             :integer          not null, primary key
#  scheme_URI     :text(65535)
#  subject        :text(65535)
#  subject_scheme :text(65535)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_dcs_subjects_on_subject  (subject)
#
FactoryBot.define do

  factory :subject, class: StashDatacite::Subject do
    subject { Faker::Lorem.word }
    subject_scheme { nil }
    scheme_URI { nil }
  end

end
