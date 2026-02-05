# == Schema Information
#
# Table name: stash_engine_counter_citations
#
#  id            :integer          not null, primary key
#  citation      :text(65535)
#  doi           :text(65535)
#  metadata      :json
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#
# Indexes
#
#  index_stash_engine_counter_citations_on_doi            (doi)
#  index_stash_engine_counter_citations_on_identifier_id  (identifier_id)
#
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
      return cites.first unless cites.blank? || cites.first&.metadata&.blank?

      datacite_metadata = Stash::DataciteMetadata.new(doi: doi)
      raw_metadata = datacite_metadata.raw_metadata
      html_citation = datacite_metadata.html_citation
      return nil if html_citation.blank? # do not save to database and return nil early

      create(citation: html_citation, metadata: raw_metadata.to_json, doi: doi, identifier_id: stash_identifier.id)
    end
  end
end
