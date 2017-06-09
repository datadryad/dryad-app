require 'open-uri'
require 'active_record/fixtures'

related_identifier_types = %w[
  DOI
  URL
  arXiv
  PMID
  ARK
  Handle
  ISBN
  ISTC
  LISSN
  LSID
  PURL
  URN
]

related_identifier_types.each do |related_identifier_type|
  StashDatacite::RelatedIdentifierType.create(related_identifier_type: related_identifier_type)
end

relation_types = %w[
  Cites
  isCitedBy
  Supplements
  IsSupplementedBy
  IsNewVersionOf
  IsPreviousVersionOf
  Continues
  IsContinuedBy
  IsPartOf
  HasPart
  IsDocumentedBy
  Documents
  IsIdenticalTo
  IsDerivedFrom
  IsSourceOf
]

relation_types.each do |relation_type|
  StashDatacite::RelationType.create(relation_type: relation_type)
end
