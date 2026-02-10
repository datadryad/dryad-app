module Stash
  module Import

    class ImportError < StandardError; end

    def self.import_publication(resource:, doi:, work_type: 'primary_article')
      cr = Integrations::Crossref.query_by_doi(doi: doi)
      return Stash::Import::Crossref.new(resource: resource, json: cr).populate_pub_update!(work_type) if cr.present?

      dc = ::Datacite::Metadata.new(doi: doi).retrieve
      return Stash::Import::Datacite.new(resource: resource, json: dc).populate_pub_update!(work_type) if dc.present?

      raise ImportError, 'No results found'
    end

    def self.import_metadata(resource:, doi:, work_type: 'primary_article')
      cr = Integrations::Crossref.query_by_doi(doi: doi)
      return Stash::Import::Crossref.new(resource: resource, json: cr).populate_resource!(work_type) if cr.present?

      dc = ::Datacite::Metadata.new(doi: doi).retrieve
      return Stash::Import::Datacite.new(resource: resource, json: dc).populate_resource!(work_type) if dc.present?

      raise ImportError, 'No results found'
    end

  end
end
