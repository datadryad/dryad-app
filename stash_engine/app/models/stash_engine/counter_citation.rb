module StashEngine
  class CounterCitation < ActiveRecord::Base
    # belongs_to :identifier, class_name: 'StashEngine::Identifier'

    # this class caches the counter_citations so it doesn't take so long to get them all from DataCite

    def self.citations(stash_identifier:)
      cite_events = Stash::EventData::Citations.new(doi: stash_identifier.identifier)
      logger.debug('before getting citation events')
      r = cite_events.results
      logger.debug('after getting citation events')
      r.map do |citation_event|
        citation(crossref_event: citation_event)
      end
    end

    # this may indicate having a crossref_event class
    def self.citation(crossref_event:)
      the_doi = citing_doi(crossref_event: crossref_event)
      citation_metadata(doi: the_doi)
    end

    # this may indicate having additional classes for crossref_event?
    def self.citing_doi(crossref_event:)
      (crossref_event['source_id'] == 'datacite' ? crossref_event['obj_id'] : crossref_event['subj_id'])
    end

    def self.citation_metadata(doi:)
      # check for cached citation
      cites = where(doi: doi)
      return cites.first unless cites.blank?

      datacite_metadata = Stash::DataciteMetadata.new(doi: doi)
      create(citation: datacite_metadata.html_citation, doi: doi)
      # { doi: doi, html: (datacite_metadata.raw_metadata.nil? ? nil : datacite_metadata.html_citation) }
    end
  end
end
