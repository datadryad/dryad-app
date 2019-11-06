module StashEngine
  class CounterCitation < ActiveRecord::Base
    # belongs_to :identifier, class_name: 'StashEngine::Identifier'

    # this class caches the counter_citations so it doesn't take so long to get them all

    def self.citations(stash_identifier:)
      cite_events = Stash::EventData::Citations.new(doi: stash_identifier.identifier)
      logger.debug('before getting citation events')
      dois = cite_events.results
      logger.debug('after getting citation events')
      dois.map do |citation_event|
        citation_metadata(doi: citation_event)
      end
    end

    def self.citation_metadata(doi:)
      # check for cached citation
      cites = where(doi: doi)
      return cites.first unless cites.blank?

      datacite_metadata = Stash::DataciteMetadata.new(doi: doi)
      create(citation: datacite_metadata.html_citation, doi: doi)
    end
  end
end
