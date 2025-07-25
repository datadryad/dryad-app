# == Schema Information
#
# Table name: dcs_contributor_groupings
#
#  id                 :bigint           not null, primary key
#  contributor_name   :text(65535)
#  contributor_type   :integer          default("funder")
#  group_label        :string(191)
#  identifier_type    :integer          default("crossref_funder_id")
#  json_contains      :json
#  required           :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  name_identifier_id :string(191)
#
require 'json'
FactoryBot.define do

  factory :contributor_grouping, class: StashDatacite::ContributorGrouping do

    contributor_name    { 'National Institutes of Health' }
    contributor_type    { 'funder' }
    identifier_type     { 'crossref_funder_id' }
    name_identifier_id  { 'http://dx.doi.org/10.13039/100000002' }
    json_contains       { JSON.parse(File.read(File.join(Rails.root, 'spec/fixtures/nih_group.json'))) }
  end
end
