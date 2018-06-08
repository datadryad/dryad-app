module StashEngine
  class CounterCitation < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    # this class caches the counter_citations so it doesn't take so long to get them all from DataCite

    def self.citations(doi:)
      cite_events = Stash::EventData::Citations.new(doi: doi)
      cite_events.results.map do |citation_event|
        # which is the DOI varies between datacite vs crossref events
        the_doi = (citation_event['source_id'] == 'datacite' ? citation_event['obj_id'] : citation_event['subj_id'])
        datacite_metadata = Stash::DataciteMetadata.new(doi: the_doi)
        { doi: the_doi, html: (datacite_metadata.raw_metadata.nil? ? nil : datacite_metadata.html_citation) }
      end
    end

  end
end
