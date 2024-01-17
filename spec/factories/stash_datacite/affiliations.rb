# == Schema Information
#
# Table name: dcs_affiliations
#
#  id           :integer          not null, primary key
#  short_name   :text(65535)
#  long_name    :text(65535)
#  abbreviation :text(65535)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  ror_id       :string(191)
#
FactoryBot.define do

  factory :affiliation, class: StashDatacite::Affiliation do
    long_name { Faker::Lorem.unique.word }
    ror_id { create(:ror_org).ror_id }
  end

end
