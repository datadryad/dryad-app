require 'serrano'

module Integrations
  class Crossref
    class << self
      def query_by_doi(doi:)
        return nil unless doi.present?

        resp = Serrano.works(ids: doi.gsub(/\s+/, ''))
        return nil unless resp.first.present? && resp.first['message'].present?

        resp.first['message']
        # Stash::Import::CrossRef.new(resource: resource, json: resp.first['message'])
      rescue Serrano::NotFound, Serrano::BadGateway, Serrano::Error, Serrano::GatewayTimeout, Serrano::InternalServerError,
             Serrano::ServiceUnavailable
        nil
      end

      def query_by_preprint_doi(doi:)
        return nil unless doi.present?

        bare = bare_doi(doi_string: doi)
        resp = Serrano.works(ids: bare.gsub(/\s+/, ''))
        return nil unless resp.first.present? && resp.first['message'].present?

        id = resp.first['message'].dig('relation', 'is-preprint-of', 0)
        return nil unless id.present? && id['id-type'] == 'doi'

        b = bare_doi(doi_string: id['id'])
        query_by_doi(doi: b)
      rescue Serrano::NotFound, Serrano::BadGateway, Serrano::Error, Serrano::GatewayTimeout, Serrano::InternalServerError,
             Serrano::ServiceUnavailable
        nil
      end

      def query_by_author_title(resource:)
        return nil if resource.blank? || resource.title&.strip.blank?

        issn, title_query, author_query = title_author_query_params(resource)
        resp = Serrano.works(issn: issn, query: title_query, query_author: author_query, filter: { type: %w[journal-article posted-content] },
                             limit: 20, sort: 'score', order: 'desc')
        resp = resp.first if resp.is_a?(Array)
        return nil unless valid_serrano_works_response(resp)

        match = match_resource_with_crossref_record(resource: resource, response: resp['message'])
        return nil if match.blank? || match.first < 0.5

        sm = match.last
        sm['ISSN'] = get_journal_issn(sm) unless sm['ISSN'].present?
        sm
        # Stash::Import::CrossRef.new(resource: resource, json: sm)
      rescue Serrano::NotFound, Serrano::BadGateway, Serrano::Error, Serrano::GatewayTimeout, Serrano::InternalServerError,
             Serrano::ServiceUnavailable
        nil
      end

      def get_journal_issn(hash)
        return nil unless hash.present? && (hash['container-title'].present? || hash['publisher'].present?)

        pub = hash['container-title'].present? ? hash['container-title'] : hash['publisher']
        pub = pub.first if pub.present? && pub.is_a?(Array)
        resp = Serrano.journals(query: pub)
        return nil unless resp.present? && resp['message'].present? && resp['message']['items'].present?
        return nil unless resp['message']['items'].first['ISSN'].present?

        resp['message']['items'].first['ISSN']
      end

      def bare_doi(doi_string:)
        bare_match = %r{^(doi:|https?://dx\.doi\.org/|https?://doi\.org/)(.+)$}
        my_match = doi_string.match(bare_match)
        my_match.present? ? my_match[2] : doi_string
      end

      private

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
        both_name_match = names.any? { |h| h[:last] == author['family']&.downcase && h[:first] == author['given']&.downcase }

        amatch += 0.05 if both_name_match
        amatch += 0.025 if last_name_match && !both_name_match
        amatch.round(3)
      end

      def valid_serrano_works_response(resp)
        resp.present? && resp['message'].present? && resp['message']['total-results'].present? &&
          resp['message']['total-results'] > 0 && resp['message']['items'].present? &&
          resp['message']['items'].is_a?(Array)
      end

      def title_author_query_params(resource)
        return [nil, nil, nil] unless resource.present?

        issn = resource.identifier&.publication_issn
        issn = CGI.escape(issn) if issn.present?
        title_query = resource.title&.gsub(/\s+/, ' ')&.strip
        title_query = CGI.escape(title_query)&.gsub(/\s/, '+') if title_query.present?
        author_query = resource.authors.map do |a|
          a.author_last_name&.strip&.presence || a.author_first_name&.strip&.presence || a.author_org_name&.strip
        end.reject(&:blank?)
        author_query = author_query.map { |a| CGI.escape(a) }.join('+') if author_query.present?

        [issn, title_query, author_query]
      end
    end
  end
end
