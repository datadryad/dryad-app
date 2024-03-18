# == Schema Information
#
# Table name: dcs_affiliations
#
#  id           :integer          not null, primary key
#  abbreviation :text(65535)
#  long_name    :text(65535)
#  short_name   :text(65535)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  ror_id       :string(191)
#
# Indexes
#
#  index_dcs_affiliations_on_long_name   (long_name)
#  index_dcs_affiliations_on_ror_id      (ror_id)
#  index_dcs_affiliations_on_short_name  (short_name)
#
FactoryBot.define do

  factory :affiliation, class: StashDatacite::Affiliation do
    long_name { Faker::Lorem.unique.word }
    ror_id { create(:ror_org).ror_id }
  end

end
