FactoryBot.define do

  factory :related_identifier, class: StashDatacite::RelatedIdentifier do

    resource

    related_identifier      { Faker::Number.number(8) }
    related_identifier_type { %w[doi ean13 eissn handle isbn issn istc lissn lsid pmid purl upc url urn].sample }
    relation_type           do
      %w[iscitedby cites issupplementto issupplementedby iscontinuedby continues isnewversionof
         ispreviousversionof ispartof haspart isreferencedby references isdocumentedby documents
         iscompiledby compiles isvariantformof isorginalformof isidenticalto hasmetadata ismetadatafor
         reviews isreviewedby isderivedfrom issourceof].sample
    end

    trait :publication_doi do
      related_identifier      { Faker::Pid.doi || Faker::Number.number(8) }
      related_identifier_type { 'doi' }
      relation_type           { 'issupplementto' }
    end

  end

end
