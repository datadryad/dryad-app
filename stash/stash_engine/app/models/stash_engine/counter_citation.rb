module StashEngine
  class CounterCitation < ApplicationRecord
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    # this class caches the counter_citations so it doesn't take so long to get them all

    def self.citations(stash_identifier:)
      cite_events = Stash::EventData::Citations.new(doi: stash_identifier.identifier)
      # logger.debug('before getting citation events')
      dois = cite_events.results
      # logger.debug('after getting citation events')
      dois.map do |citation_event|
        citation_metadata(doi: citation_event, stash_identifier: stash_identifier)
      end
    end

    # gets cached citation or retrieves a new one
    def self.citation_metadata(doi:, stash_identifier:)
      # check for cached citation
      cites = where(doi: doi)
      return cites.first unless cites.blank?

      datacite_metadata = Stash::DataciteMetadata.new(doi: doi)
      html_citation = datacite_metadata.html_citation
      html_citation = "Citation text unavailable for <a href=\"#{doi}\" target=\"_blank\">#{doi}</a>" if html_citation.blank?
      create(citation: html_citation, doi: doi, identifier_id: stash_identifier.id)
    end
  end
end
