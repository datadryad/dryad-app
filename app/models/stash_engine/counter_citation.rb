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
      return cites.first unless cites.blank? || cites.first&.metadata.blank?

      raw_metadata = Integrations::Doi.new.citeproc_json(doi)
      return nil if raw_metadata.in?([nil, false]) # do not save to database and return nil early

      cm = create(metadata: raw_metadata, doi: doi, identifier_id: stash_identifier.id)
      cm.update(citation: cm.html_citation)
      cm
    end

    def html_citation
      return metadata if metadata.in?([nil, false])

      citation_array = []
      citation_array << "#{author_names}#{year_published ? " (#{year_published})" : ''}"
      citation_array << "#{title.html_safe}#{resource_type}"
      citation_array << journal
      citation_array << publisher unless metadata['type'].include?('journal')
      citation_array << "<a href=\"#{doi_link}\" target=\"_blank\">#{doi_link}</a>".html_safe
      citation_array.reject(&:blank?).join('. ')
    end

    def author_names
      names = metadata['author']
      return '' if names.blank?

      names = names.map { |i| name_finder(i) }
      return "#{names.first(3).join('; ')} et al." if names.length > 4

      names.join('; ')
    end

    def year_published
      dp = metadata.dig('issued', 'date-parts')
      return dp.first.first unless dp.blank?

      ''
    end

    def title
      metadata['title']
    end

    def publisher
      metadata['publisher']
    end

    def journal
      metadata['container-title']
    end

    def resource_type
      return ' [Preprint]' if %w[posted-content preprint].include?(metadata['type'])
      return ' [Dataset]' if metadata['type'] == 'dataset'
      return ' [Software]' if metadata['type'] == 'software'

      ''
    end

    def doi_link
      "https://doi.org/#{doi}"
    end

    # finds the name from the names hash, might be item['literal'] or item['given'] and item['family']
    def name_finder(item)
      return "#{item['family']}, #{item['given']}" if item['family'] || item['given']

      item['literal']
    end
  end
end
