class ModifyRelatedIdentifierTypeAsEnum < ActiveRecord::Migration
  def change
    remove_column :dcs_related_identifiers, :related_identifier_type_id
    remove_column :dcs_related_identifiers, :relation_type_id

    add_column :dcs_related_identifiers, :scheme_type, :string,
               after: :related_identifier

    add_column :dcs_related_identifiers, :scheme_URI, :text,
               after: :related_identifier

    add_column :dcs_related_identifiers, :related_metadata_scheme, :text,
               after: :related_identifier

    add_column :dcs_related_identifiers, :relation_type, "ENUM('iscitedby', 'cites', 'issupplementto', 'issupplementedby', " \
      "'iscontinuedby', 'continues', 'isnewversionof', 'ispreviousversionof', 'ispartof', 'haspart', " \
      "'isreferencedby', 'references', 'isdocumentedby', 'documents', 'iscompiledby', 'compiles', " \
      "'isvariantformof', 'isoriginalformof', 'isidenticalto', 'hasmetadata', 'ismetadatafor', 'reviews', " \
      "'isreviewedby', 'isderivedfrom', 'issourceof') DEFAULT NULL",
               after: :related_identifier

    add_column :dcs_related_identifiers, :related_identifier_type, "ENUM('ark', 'arxiv', 'bibcode', 'doi', 'ean13', " \
      "'eissn', 'handle', 'isbn', 'issn', 'istc', 'lissn', 'lsid', 'pmid', 'purl', 'upc', 'url', 'urn') DEFAULT NULL",
               after: :related_identifier
  end
end
