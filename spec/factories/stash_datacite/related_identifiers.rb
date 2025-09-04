# == Schema Information
#
# Table name: dcs_related_identifiers
#
#  id                      :integer          not null, primary key
#  added_by                :integer          default("default")
#  hidden                  :boolean          default(FALSE)
#  related_identifier      :text(65535)
#  related_identifier_type :string
#  related_metadata_scheme :text(65535)
#  relation_type           :string
#  scheme_URI              :text(65535)
#  scheme_type             :text(65535)
#  verified                :boolean          default(FALSE)
#  work_type               :integer          default("undefined")
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  fixed_id                :text(65535)
#  resource_id             :integer
#
# Indexes
#
#  index_dcs_related_identifiers_on_related_identifier  (related_identifier)
#  index_dcs_related_identifiers_on_resource_id         (resource_id)
#
FactoryBot.define do

  factory :related_identifier, class: StashDatacite::RelatedIdentifier do

    resource

    related_identifier      { "https://doi.org/#{Faker::Pid.doi}" }
    related_identifier_type { 'doi' }
    relation_type           { %w[iscitedby issupplementedby isderivedfrom issourceof isdocumentedby].sample }
    work_type               { %w[article dataset preprint software supplemental_information data_management_plan].sample }

    trait :publication_doi do
      related_identifier      { Faker::Pid.doi }
      related_identifier_type { 'doi' }
      relation_type           { 'iscitedby' }
      work_type { 'primary_article' }
      verified { true }
    end

  end

end
