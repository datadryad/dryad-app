# frozen_string_literal: true

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
require 'http'

# rubocop:disable Metrics/ClassLength
module StashDatacite

  class ExternalServerError < RuntimeError; end

  class RelatedIdentifier < ApplicationRecord
    self.table_name = 'dcs_related_identifiers'
    has_paper_trail

    belongs_to :resource, class_name: StashEngine::Resource.to_s

    scope :completed, -> { where("TRIM(IFNULL(related_identifier, '')) > ''") } # only non-null & blank

    RelationTypes = Datacite::Mapping::RelationType.map(&:value)

    RelationTypesEnum = RelationTypes.to_h { |i| [i.downcase.to_sym, i.downcase] }
    RelationTypesStrToFull = RelationTypes.to_h { |i| [i.downcase, i] }

    RelatedIdentifierTypes = Datacite::Mapping::RelatedIdentifierType.map(&:value)

    RelatedIdentifierTypesEnum = RelatedIdentifierTypes.to_h { |i| [i.downcase.to_sym, i.downcase] }
    RelatedIdentifierTypesStrToFull = RelatedIdentifierTypes.to_h { |i| [i.downcase, i] }

    # rubocop:disable Naming/ConstantName
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
    # rubocop:enable Naming/ConstantName

    enum :work_type, { undefined: 0, article: 1, dataset: 2, preprint: 3, software: 4, supplemental_information: 5,
                       primary_article: 6, data_management_plan: 7 } # changing to make the enum index more explicit

    enum :added_by, { default: 0, zenodo: 1, simple_relation: 2, api_simple: 3 }

    validates :related_identifier, uniqueness: { allow_blank: true, scope: :resource_id, message: 'The DOI or URL is already added to the dataset' }
    validates :work_type, uniqueness: { scope: :resource_id, conditions: -> {
      where(work_type: :primary_article)
    }, message: 'Only one Primary article is allowed' }

    WORK_TYPE_CHOICES = { article: 'Article', dataset: 'Dataset', preprint: 'Preprint', software: 'Software',
                          supplemental_information: 'Supplemental information',
                          data_management_plan: 'Data management plan' }.with_indifferent_access

    # because the plural of Software is Software and not "Softwares" like Rails thinks
    WORK_TYPE_CHOICES_PLURAL = { article: 'Articles', dataset: 'Datasets', preprint: 'Preprints', software: 'Software',
                                 supplemental_information: 'Supplemental information' }.with_indifferent_access

    WORK_TYPES_TO_RELATION_TYPE = { article: 'iscitedby',
                                    dataset: 'issupplementedby',
                                    preprint: 'iscitedby',
                                    software: 'isderivedfrom',
                                    supplemental_information: 'issourceof',
                                    primary_article: 'iscitedby',
                                    data_management_plan: 'isdocumentedby' }.with_indifferent_access

    # these keys will be case-insensitive matches
    ACCESSION_TYPES = {
      'sra' => 'https://www.ncbi.nlm.nih.gov/sra/',
      'dbgap' => 'https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/study.cgi?study_id=',
      'geo' => 'https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=',
      'genbank' => 'https://www.ncbi.nlm.nih.gov/nuccore/',
      'bioproject' => 'https://www.ncbi.nlm.nih.gov/bioproject/',
      'ebi' => 'https://www.ebi.ac.uk/arrayexpress/experiments/',
      'ega' => 'https://www.ebi.ac.uk/ega/datasets/',
      'treebase' => 'https://www.treebase.org/treebase-web/search/study/summary.html?id=',
      'treebase_uri' => 'http://purl.org/phylo/treebase/phylows/study/'
    }.with_indifferent_access

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

    def work_type_friendly
      WORK_TYPE_CHOICES[work_type] || work_type.humanize
    end

    def work_type_friendly_plural
      WORK_TYPE_CHOICES_PLURAL[work_type] || work_type.humanize.pluralize
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
      "This #{resource&.resource_type&.resource_type} #{relation_name_english} #{related_identifier_type_friendly}: #{related_identifier}"
    end

    def self.set_latest_zenodo_relations(resource:)
      resource.related_identifiers.where(added_by: 'zenodo').destroy_all

      # software file relation
      sfw_copy = resource.zenodo_copies.software.first
      if sfw_copy&.software_doi.present? && resource.software_files.present_files.count.positive?
        doi = standardize_doi(sfw_copy.software_doi)
        create(related_identifier: doi,
               related_identifier_type: 'doi',
               relation_type: 'isderivedfrom',
               work_type: 'software',
               verified: true,
               resource_id: resource.id,
               added_by: 'zenodo')
      end

      # supplemental file relations
      supp_copy = resource.zenodo_copies.supp.first

      return unless supp_copy&.software_doi.present? && resource.supp_files.present_files.count.positive?

      doi = standardize_doi(supp_copy.software_doi)
      create(related_identifier: doi,
             related_identifier_type: 'doi',
             relation_type: 'issourceof',
             work_type: 'supplemental_information',
             verified: true,
             resource_id: resource.id,
             added_by: 'zenodo')
    end

    def self.remove_zenodo_relation(resource_id:, doi:)
      doi = standardize_doi(doi)
      existing_item = where(resource_id: resource_id).where(related_identifier_type: 'doi')
        .where(related_identifier: doi).last
      existing_item.destroy! if existing_item
    end

    def valid_doi_format?
      RelatedIdentifier.valid_doi_format?(related_identifier)
    end

    def valid_url_format?
      RelatedIdentifier.valid_url?(related_identifier)
    end

    # the format is very strict to use the recommended one CrossRef/DataCite suggest, but could be transformed into this below
    def self.valid_doi_format?(doi)
      m = doi.match(%r{^https://doi.org/10\.\d{4,9}/[-._;()/:a-zA-Z0-9]+$})
      return false if m.nil?

      true
    end

    # inserts or updates as is appropriate.  Usually inserts, but may update if the doi for resource is already in the database or
    # for special circumstances like "there can be only one" primary articles.  Also assumes always a doi for simplicity of use.
    # DOI is the one of the external item, adds to the resource given, work types re list in the enum.
    def self.upsert_simple_relation(doi:, resource_id:, work_type:, added_by: 'simple_relation', verified: true)
      work_type = work_type.to_s # just in case it's a symbol instead of a string

      raise ArgumentError, 'work type is invalid' unless work_types.keys.include?(work_type)

      fixed_doi = standardize_doi(doi)
      existing_item = where(resource_id: resource_id).where(related_identifier: fixed_doi).first
      existing_primary = where(resource_id: resource_id).where(work_type: :primary_article).first

      if existing_primary.present? && work_type == 'primary_article' && fixed_doi != existing_primary.related_identifier
        # this is a different primary article from before, so demote old to article and this will become the new primary article
        existing_primary.update!(work_type: 'article')
        existing_item = nil # force a new insert instead of normal update to this item
      end

      if existing_item.present?
        existing_item.update(related_identifier: fixed_doi,
                             related_identifier_type: 'doi',
                             work_type: work_type,
                             added_by: added_by,
                             verified: verified,
                             relation_type: WORK_TYPES_TO_RELATION_TYPE[work_type])
        existing_item
      else
        create(related_identifier: fixed_doi,
               related_identifier_type: 'doi',
               work_type: work_type,
               added_by: added_by,
               verified: verified,
               relation_type: WORK_TYPES_TO_RELATION_TYPE[work_type],
               resource_id: resource_id)
      end
    end

    # look for doi in string and make standardized format
    def self.standardize_doi(doi)
      return doi if valid_doi_format?(doi) # don't mess if it is OK

      m = doi.match(%r{10\.\d{4,9}/[-._;()/:a-zA-Z0-9]+})
      return doi if m.nil? # can't find a doi in the string and can't fix, so leave it alone

      "https://doi.org/#{m}" # return a standardized version of a doi
    end

    def live_url_valid?
      return false unless valid_url_format?

      # NOTE: this follows up to 10 redirects
      http = HTTP.timeout(connect: 10, read: 10).timeout(10).follow(max_hops: 10)
      begin
        retries ||= 0
        resp = http.head(related_identifier)
        return true if resp.status.code > 199 && resp.status.code < 300 # 200 range status code

        # If we hit a CloudFlare server that wants to use complex JS to verify we are a "real" browser,
        # just assume the URL redirected to a valid location
        return true if (resp.status.code == 503) && resp.to_s.include?('Checking your browser before accessing')

        raise StashDatacite::ExternalServerError, "Status code: #{resp.status.code}" if resp.status.code > 499

        return false
      rescue HTTP::Error, HTTP::TimeoutError, StashDatacite::ExternalServerError => e
        retry if (retries += 1) < 3
        # IDK what we really do if there are HTTP errors or timeout errors aside from treating it as
        # a bad attempt at resolving the URL and logging it.

        Rails.logger.error("Failed to live validate URL #{related_identifier}\n" \
                           "#{e.full_message}")
      end
      false
    end

    def self.standardize_format(identifier)
      return '' if identifier.blank?

      identifier = identifier.strip
      identifier = RelatedIdentifier.standardize_doi(identifier)

      return identifier if identifier.start_with?('http')

      ACCESSION_TYPES.each do |k, v|
        next unless identifier.downcase.start_with?("#{k}:")

        bare_id = identifier[k.length + 1..].strip # get rest of the string after that.
        return "#{v}#{ERB::Util.url_encode(bare_id)}"

      end

      identifier
    end

    def self.identifier_type_from_str(str)
      return 'url' if str.blank?

      return 'doi' if %r{^https?://(dx\.)?doi\.org}.match(str)

      'url'
    end

    def self.valid_url?(string)
      uri = URI.parse(string)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end

    private

    def strip_whitespace
      self.related_identifier = related_identifier.strip unless related_identifier.nil?
    end
  end

end
# rubocop:enable Metrics/ClassLength
