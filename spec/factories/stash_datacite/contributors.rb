# == Schema Information
#
# Table name: dcs_contributors
#
#  id                 :integer          not null, primary key
#  contributor_name   :text(65535)
#  contributor_type   :string           default("funder")
#  identifier_type    :string
#  name_identifier_id :string(191)
#  resource_id        :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  award_number       :text(65535)
#  funder_order       :integer
#  award_description  :string(191)
#
FactoryBot.define do

  factory :contributor, class: StashDatacite::Contributor do

    resource

    contributor_name    { Faker::Company.name }
    contributor_type    { 'funder' }
    identifier_type     { 'crossref_funder_id' }
    name_identifier_id  { Faker::Pid.doi }
    award_number        { Faker::Alphanumeric.alphanumeric(number: 8, min_alpha: 2, min_numeric: 4) }
  end

end
