# == Schema Information
#
# Table name: dcs_contributors
#
#  id                 :integer          not null, primary key
#  award_description  :string(191)
#  award_number       :text(65535)
#  award_title        :string(191)
#  award_uri          :string(191)
#  contributor_name   :text(65535)
#  contributor_type   :string           default("funder")
#  funder_order       :integer
#  identifier_type    :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  name_identifier_id :string(191)
#  resource_id        :integer
#
# Indexes
#
#  index_dcs_contributors_on_contributor_type    (contributor_type)
#  index_dcs_contributors_on_funder_order        (funder_order)
#  index_dcs_contributors_on_identifier_type     (identifier_type)
#  index_dcs_contributors_on_name_identifier_id  (name_identifier_id)
#  index_dcs_contributors_on_resource_id         (resource_id)
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
