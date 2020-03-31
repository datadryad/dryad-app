FactoryBot.define do

  factory :subject, class: StashDatacite::Subject do
    subject { Faker::Lorem.word }
    subject_scheme { nil }
    scheme_URI { nil }
  end

end
