module StashDatacite
  class RelatedIdentifier < ActiveRecord::Base
    self.table_name = 'dcs_related_identifiers'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    RelationTypes = %w(IsCitedBy Cites IsSupplementTo IsSupplementedBy IsContinuedBy Continues IsNewVersionOf
              IsPreviousVersionOf IsPartOf HasPart IsReferencedBy References IsDocumentedBy Documents IsCompiledBy
              Compiles IsVariantFormOf IsOriginalFormOf IsIdenticalTo HasMetadata IsMetadataFor Reviews IsReviewedBy
              IsDerivedFrom IsSourceOf)

    RelationTypesEnum = RelationTypes.map{|i| [i.downcase.to_sym, i.downcase]}.to_h
    RelationTypesStrToFull = RelationTypes.map{|i| [i.downcase, i]}.to_h

    RelatedIdentifierTypes = %w(ARK arXiv bibcode DOI EAN13 EISSN Handle ISBN ISSN ISTC LISSN LSID PMID PURL UPC URL URN)

    RelatedIdentifierTypesEnum = RelatedIdentifierTypes.map{|i| [i.downcase.to_sym, i.downcase]}.to_h
    RelatedIdentifierTypesStrToFull = RelatedIdentifierTypes.map{|i| [i.downcase, i]}.to_h


    before_save :strip_whitespace

    def relation_type_friendly=(type)
      # self required here to work correctly
      self.relation_type = type.to_s.downcase unless type.blank?
    end

    def relation_type_friendly
      return nil if relation_type.blank?
      RelationTypesStrToFull[relation_type]
    end

    def relation_name_english
      return '' if relation_type_friendly.nil?
      relation_type_friendly.scan(/[A-Z]{1}[a-z]*/).map{|i| i.downcase}.join(' ')
    end

    def related_identifier_type_friendly=(type)
      # self required here to work correctly
      self.related_identifier_type = type.to_s.downcase unless type.blank?
    end

    def related_identifier_type_friendly
      return nil if related_identifier_type.blank?
      RelatedIdentifierTypesStrToFull[related_identifier_type]
    end

    # this is to provide a useful message about the related identifier
    def to_s
      "This dataset #{relation_name_english} #{related_identifier_type_friendly}: #{related_identifier}"
    end

    private
    def strip_whitespace
      self.related_identifier = self.related_identifier.strip unless self.related_identifier.nil?
    end
  end
end
