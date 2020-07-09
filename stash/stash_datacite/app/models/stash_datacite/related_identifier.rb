# frozen_string_literal: true

module StashDatacite
  class RelatedIdentifier < ActiveRecord::Base
    self.table_name = 'dcs_related_identifiers'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
    include StashEngine::Concerns::ResourceUpdated

    scope :completed, -> { where("TRIM(IFNULL(related_identifier, '')) > ''") } # only non-null & blank

    RelationTypes = Datacite::Mapping::RelationType.map(&:value)

    RelationTypesEnum = RelationTypes.map { |i| [i.downcase.to_sym, i.downcase] }.to_h
    RelationTypesStrToFull = RelationTypes.map { |i| [i.downcase, i] }.to_h

    RelatedIdentifierTypes = Datacite::Mapping::RelatedIdentifierType.map(&:value)

    RelatedIdentifierTypesEnum = RelatedIdentifierTypes.map { |i| [i.downcase.to_sym, i.downcase] }.to_h
    RelatedIdentifierTypesStrToFull = RelatedIdentifierTypes.map { |i| [i.downcase, i] }.to_h

    RelatedIdentifierTypesLimited = { DOI: 'doi', ARK: 'ark', ArXiv: 'arxiv',
                                      Handle: 'handle', ISBN: 'isbn', PMID: 'pmid',
                                      PURL: 'purl', URL: 'url', URN: 'urn' }.freeze

    RelationTypesLimited = { cites: 'cites', 'is cited by': 'iscitedby', supplements: 'issupplementto',
                             'is supplemented by': 'issupplementedby', continues: 'continues',
                             'is continued by': 'iscontinuedby',
                             'is a new version of': 'isnewversionof', 'is a previous version of': 'ispreviousversionof',
                             'is part of': 'ispartof', 'has part': 'haspart', documents: 'documents',
                             'is documented by': 'isdocumentedby',
                             'is identical to': 'isidenticalto', 'is derived from': 'isderivedfrom',
                             'is source of': 'issourceof' }.freeze

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

      relation_type_friendly.scan(/[A-Z]{1}[a-z]*/).map(&:downcase).join(' ')
    end

    def self.relation_type_mapping_obj(str)
      return nil if str.nil?

      Datacite::Mapping::RelationType.find_by_value(str)
    end

    def relation_type_mapping_obj
      return nil if relation_type_friendly.nil?

      RelatedIdentifier.relation_type_mapping_obj(relation_type_friendly)
    end

    def related_identifier_type_friendly=(type)
      # self required here to work correctly
      self.related_identifier_type = type.to_s.downcase unless type.blank?
    end

    def related_identifier_type_friendly
      return nil if related_identifier_type.blank?

      RelatedIdentifierTypesStrToFull[related_identifier_type]
    end

    def self.related_identifier_type_mapping_obj(str)
      return nil if str.nil?

      Datacite::Mapping::RelatedIdentifierType.find_by_value(str)
    end

    def related_identifier_type_mapping_obj
      return nil if related_identifier_type_friendly.nil?

      RelatedIdentifier.related_identifier_type_mapping_obj(related_identifier_type_friendly)
    end

    # this is to provide a useful message about the related identifier
    def to_s
      "This dataset #{relation_name_english} #{related_identifier_type_friendly}: #{related_identifier}"
    end

    def self.add_zenodo_relation(resource_id:, doi:)
      existing_item = where(resource_id: resource_id).where(related_identifier_type: 'doi')
        .where(relation_type: 'issupplementto').where('related_identifier LIKE "%zenodo%"').last
      if existing_item.nil?
        create(related_identifier: doi, related_identifier_type: 'doi', relation_type: 'issupplementto',
               resource_id: resource_id)
      else
        existing_item.update(related_identifier: doi)
      end
    end

    private

    def strip_whitespace
      self.related_identifier = related_identifier.strip unless related_identifier.nil?
    end
  end
end
