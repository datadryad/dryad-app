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

    related_identifier      { Faker::Number.number(digits: 8) }
    related_identifier_type { %w[doi ean13 eissn handle isbn issn istc lissn lsid pmid purl upc url urn].sample }
    relation_type           do
      %w[iscitedby cites issupplementto issupplementedby iscontinuedby continues isnewversionof ispreviousversionof ispartof
         haspart isreferencedby references isdocumentedby documents iscompiledby compiles isvariantformof isoriginalformof
         isidenticalto hasmetadata ismetadatafor reviews isreviewedby isderivedfrom issourceof].sample
    end

    trait :publication_doi do
      related_identifier      { Faker::Pid.doi }
      related_identifier_type { 'doi' }
      relation_type           { 'iscitedby' }
      work_type { 'article' }
      verified { true }
    end

  end

end
