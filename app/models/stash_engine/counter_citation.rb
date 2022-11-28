module StashEngine
  class CounterCitation < ApplicationRecord
    self.table_name = 'stash_engine_counter_citations'
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    # this class caches the counter_citations so it doesn't take so long to get them all

    def self.citations(stash_identifier:)
      cite_events = Stash::EventData::Citations.new(doi: stash_identifier.identifier)
      # logger.debug('before getting citation events')
      dois = cite_events.results
      # logger.debug('after getting citation events')
      # dois, but eliminate blank citations
      dois.map do |citation_event|
        citation_metadata(doi: citation_event, stash_identifier: stash_identifier)
      end.compact
    end

    # gets cached citation or retrieves a new one
    def self.citation_metadata(doi:, stash_identifier:)
      # check for cached citation
      cites = where(doi: doi)
      return cites.first unless cites.blank?

      datacite_metadata = Stash::DataciteMetadata.new(doi: doi)
      html_citation = datacite_metadata.html_citation
      return nil if html_citation.blank?  # do not save to database and return nil early

      create(citation: html_citation, doi: doi, identifier_id: stash_identifier.id)
    end
  end
end
