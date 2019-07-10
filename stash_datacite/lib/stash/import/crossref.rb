require 'amatch'

require_relative '../../../app/models/stash_datacite/proposed_change'

module Stash
  module Import
    # rubocop:disable Metrics/ClassLength
    class Crossref

      include Amatch

      CROSSREF_FIELD_LIST = %w[abstract author container-title DOI funder published-online
                               published-print publisher score title type URL].freeze

      def initialize(resource:, crossref_json:)
        @resource = resource
        crossref_json = JSON.parse(crossref_json) if crossref_json.is_a?(String)
        @sm = crossref_json # which came form crossref (x-ref) ... see class methods below
      end

      class << self
        def query_by_doi(resource:, doi:)
          return nil unless resource.present? && doi.present?

          resp = Serrano.works(ids: doi)
          return nil unless resp.first.present? && resp.first['message'].present?

          new(resource: resource, crossref_json: resp.first['message'])
        rescue Serrano::NotFound, Serrano::InternalServerError
          nil
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def query_by_author_title(resource:)
          return nil if resource.blank? || resource.title&.strip.blank?
          issn, title_query, author_query = title_author_query_params(resource)
          resp = Serrano.works(issn: issn, select: CROSSREF_FIELD_LIST, query: title_query,
                               query_author: author_query, limit: 20, sort: 'score', order: 'desc')
          resp = resp.first if resp.is_a?(Array)
          return nil unless valid_serrano_works_response(resp)

          match = match_resource_with_crossref_record(resource: resource, response: resp['message'])
          return nil if match.blank? || match.first < 0.5

          sm = match.last
          sm['ISSN'] = get_journal_issn(sm) unless sm['ISSN'].present?
          new(resource: resource, crossref_json: sm)
        rescue Serrano::NotFound, Serrano::InternalServerError
          nil
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def from_proposed_change(proposed_change:)
          return new(resource: nil, crossref_json: {}) unless proposed_change.is_a?(StashEngine::ProposedChange)
          identifier = StashEngine::Identifier.find(proposed_change.identifier_id)
          if proposed_change.publication_date.present?
            date_parts = [proposed_change.publication_date.year, proposed_change.publication_date.month,
                          proposed_change.publication_date.day]
          end
          message = {
            'author' => JSON.parse(proposed_change.authors),
            'published-online' => { 'date-parts' => date_parts },
            'DOI' => proposed_change.publication_doi,
            'publisher' => proposed_change.publication_name,
            'title' => [proposed_change.title],
            'URL' => proposed_change.url,
            'score' => proposed_change.score,
            'provenance_score' => proposed_change.provenance_score
          }
          new(resource: identifier.latest_resource, crossref_json: message)
        end
      end

      def populate_resource!
        return unless @sm.present? && @resource.present?
        populate_abstract
        populate_authors
        populate_cited_by
        populate_funders
        populate_publication_date
        populate_publication_doi
        populate_publication_issn
        populate_publication_name
        populate_title
        @resource.save
        @resource.reload
      end

      def to_proposed_change
        return nil unless @sm.present? && @resource.present?

        # Skip if the identifier already has proposed changes
        return unless StashEngine::ProposedChange.where(identifier_id: @resource.identifier.id).empty?

        params = {
          identifier_id: @resource.identifier.id,
          approved: false,
          authors: @sm['author'].to_json,
          provenance: 'crossref',
          publication_date: date_parts_to_date(publication_date),
          publication_doi: @sm['DOI'],
          publication_issn: @sm['ISSN']&.first,
          publication_name: publisher.is_a?(Array) ? publisher&.first : publisher,
          score: @sm['score'],
          provenance_score: @sm['provenance_score'],
          title: @sm['title']&.first&.to_s,
          url: @sm['URL']
        }
        pc = StashEngine::ProposedChange.new(params)
        resource_will_change?(proposed_change: pc) ? pc : nil
      end

      private

      class << self
        def match_resource_with_crossref_record(resource:, response:)
          return nil unless resource.present? && response.present? && resource.title.present?
          scores = []
          names = resource.authors.map do |author|
            { first: author.author_first_name&.downcase, last: author.author_last_name&.downcase }
          end
          orcids = resource.authors.map { |author| author.author_orcid&.downcase }

          response['items'].each do |item|
            next unless item['title'].present?
            scores << crossref_item_scoring(resource, item, names, orcids)
          end
          # Sort by the score and return the one with the highest score
          scores.max_by { |a| a[0] }
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def crossref_item_scoring(resource, item, names, orcids)
          return 0.0 unless resource.present? && resource.title.present? && item.present? && item['title'].present?
          # Compare the titles using the Amatch NLP library
          amatch = resource.title.pair_distance_similar(item['title'].first)
          # If authors are available compare them as well
          if item['author'].present? && (names.present? || orcids.present?)
            item['author'].each do |author|
              next unless author['family'].present?
              amatch += crossref_author_scoring(names, orcids, author)
            end
          end
          item['provenance_score'] = item['score']
          item['score'] = amatch
          [amatch, item]
        end

        def crossref_author_scoring(names, orcids, author)
          amatch = 0.0
          # An ORCID match is stronger than a name match
          amatch += 0.1 if author['ORCID'].present? && orcids.include?(author['ORCID']&.downcase)
          return amatch unless names.present? && names.any?

          # Last name matches are useful but both first+last matches are better
          last_name_match = names.map { |h| h[:last] }.include?(author['family']&.downcase)
          both_name_match = names.select { |h| h[:last] == author['family']&.downcase && h[:first] == author['given']&.downcase }.any?

          amatch += 0.05 if both_name_match
          amatch += 0.025 if last_name_match && !both_name_match
          amatch.round(3)
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def valid_serrano_works_response(resp)
          resp.present? && resp['message'].present? && resp['message']['total-results'].present? &&
            resp['message']['total-results'] > 0 && resp['message']['items'].present? &&
            resp['message']['items'].is_a?(Array)
        end

        def title_author_query_params(resource)
          return [nil, nil, nil] unless resource.present?
          issn = resource.identifier.internal_data.where(data_type: 'publicationISSN').first&.value
          issn = CGI.escape(issn) if issn.present?
          title_query = resource.title&.gsub(/\s+/, ' ')&.strip
          title_query = CGI.escape(title_query)&.gsub(/\s/, '+') if title_query.present?
          author_query = resource.authors.map { |a| a.author_last_name.gsub(/\s+/, ' ')&.strip }
          author_query = author_query.map { |a| CGI.escape(a) }.join('+') if author_query.present?

          [issn, title_query, author_query]
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def get_journal_issn(hash)
          return nil unless hash.present? && (hash['container-title'].present? || hash['publisher'].present?)

          publisher = hash['container-title'].present? ? hash['container-title'] : hash['publisher']
          resp = Serrano.journals(query: publisher)
          return nil unless resp.present? && resp['message'].present? && resp['message']['items'].present?
          return nil unless resp['message']['items'].first['ISSN'].present?

          resp['message']['items'].first['ISSN']
        end
        # rubocop:enable Metrics/CyclomaticComplexity

      end

      def resource_will_change?(proposed_change:)
        if proposed_change.authors.present?
          auths = JSON.parse(proposed_change.authors).map do |auth|
            StashEngine::Author.new(resource_id: @resource.id, author_orcid: auth['ORCID'],
                                    author_first_name: auth['given'], author_last_name: auth['family'])
          end
        end

        proposed_change.publication_date != @resource.publication_date ||
          internal_datum_will_change?(proposed_change: proposed_change) ||
          (proposed_change.authors.present? && (auths & @resource.authors).any?)
      end

      def internal_datum_will_change?(proposed_change:)
        internal_data = @resource.identifier.internal_data
        proposed_change.publication_name != internal_data.select { |d| d.data_type == 'publicationName' }.first&.value ||
          proposed_change.publication_name != internal_data.select { |d| d.data_type == 'publicationISSN' }.first&.value ||
          proposed_change.publication_name != internal_data.select { |d| d.data_type == 'publicationDOI' }.first&.value
      end

      def populate_abstract
        return unless @sm['abstract'].present?
        abstract = @resource.descriptions.first_or_initialize(description_type: 'abstract')
        abstract.update(description: @sm['abstract'])
      end

      def populate_affiliation(author, hash)
        affil_name = (hash['affiliation']&.first ? hash['affiliation'].first['name'] : nil)
        affiliation = StashDatacite::Affiliation.from_long_name(affil_name) if affil_name.present?
        affiliation.authors << author if affiliation.present? && !affiliation.authors.include?(author)
        affiliation.save if affiliation.present?
      end

      def populate_author(hash)
        new_auth = StashEngine::Author.new(resource_id: @resource.id, author_orcid: hash['ORCID'],
                                           author_first_name: hash['given'], author_last_name: hash['family'])
        # Try to find an existing author already attached to the resource
        author = @resource.authors.select { |a| a == new_auth }.first
        @resource.authors << new_auth unless author.present?
        author = @resource.authors.last unless author.present?

        author.author_first_name = hash['given'] if hash['given'].present?
        author.author_last_name = hash['family'] if hash['family'].present?
        author.author_orcid = hash['ORCID'].match(/[0-9\-]{19}$/).to_s if hash['ORCID'].present?
        populate_affiliation(author, hash)
        author.save
      end

      def populate_authors
        return unless @sm['author'].present? && @sm['author'].any?
        @sm['author'].each do |xr_author|
          populate_author(xr_author)
        end
      end

      def populate_cited_by
        return unless @sm['URL'].present?
        @resource.related_identifiers.new(related_identifier: @sm['URL'], related_identifier_type: 'doi', relation_type: 'iscitedby')
      end

      def populate_funders
        return unless @sm['funder'].present? && @sm['funder'].is_a?(Array) && @sm['funder'].any?
        @sm['funder'].each do |xr_funder|
          next if xr_funder['name'].blank?
          if xr_funder['award'].blank?
            @resource.contributors.new(contributor_name: xr_funder['name'], contributor_type: 'funder')
            next
          end
          xr_funder['award'].each do |xr_award|
            @resource.contributors.new(contributor_name: xr_funder['name'], contributor_type: 'funder', award_number: xr_award)
          end
        end
      end

      def populate_publication_date
        return unless publication_date.present?
        @resource.publication_date = date_parts_to_date(publication_date)
      end

      def populate_publication_doi
        return unless @sm['DOI'].present?
        datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: @resource.identifier.id,
                                                                 data_type: 'publicationDOI')
        datum.update(value: @sm['DOI'])
      end

      def populate_publication_issn
        return unless @sm['ISSN'].present? && @sm['ISSN'].first.present?
        datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: @resource.identifier.id,
                                                                 data_type: 'publicationISSN')
        datum.update(value: @sm['ISSN'].first)
      end

      def populate_publication_name
        return unless publisher.present?
        datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: @resource.identifier.id,
                                                                 data_type: 'publicationName')
        datum.update(value: publisher)
      end

      def populate_title
        return unless @sm['title'].present? && @sm['title'].any?
        @resource.title = @sm['title'].first
      end

      def publication_date
        return @sm['published-online']['date-parts'] if @sm['published-online'].present? && @sm['published-online']['date-parts'].present?
        return @sm['published-print']['date-parts'] if @sm['published-print'].present? && @sm['published-print']['date-parts'].present?
        nil
      end

      def publisher
        @sm['container-title'].present? ? @sm['container-title'] : @sm['publisher']
      end

      def date_parts_to_date(parts_array)
        return nil unless parts_array.present? && parts_array.is_a?(Array)
        Date.parse(parts_array.join('-'))
      rescue StandardError
        nil
      end

      def date_to_date_parts(date)
        date = date.is_a?(Date) ? date : Date.parse(date.to_s)
        [date.year, date.month, date.day]
      rescue StandardError
        nil
      end

    end
    # rubocop:enable Metrics/ClassLength

  end
end
