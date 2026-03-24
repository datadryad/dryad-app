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

      def query_by_preprint_doi(resource:, doi:)
        return nil unless doi.present?

        bare = bare_doi(doi_string: doi)
        resp = Serrano.works(ids: bare.gsub(/\s+/, ''))
        return nil unless resp.first.present? && resp.first['message'].present?

        id = resp.first['message'].dig('relation', 'is-preprint-of', 0)
        return nil unless id.present? && id['id-type'] == 'doi'

        b = bare_doi(doi_string: id['id'])
        item = query_by_doi(doi: b)
        crossref_item_scoring(resource, item)&.last
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
        return nil if match.blank? || match.first < 0.7

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

      def exclude_dois(resource)
        # processed pcs and all ris except articles (often added incorrectly)
        (
          resource.identifier.proposed_changes.processed.pluck(:publication_doi) +
          resource.related_identifiers.where('work_type != 1').select("REGEXP_SUBSTR(`related_identifier`, '(10..+)') as doi")
            .map(&:doi).reject(&:blank?)
        ).uniq
      end

      def match_resource_with_crossref_record(resource:, response:)
        return nil unless resource.present? && response.present? && resource.title.present?

        scores = []
        response['items'].each do |item|
          next unless item['title'].present?
          next if exclude_dois(resource).include?(item['DOI'])

          scores << crossref_item_scoring(resource, item)
        end
        # Sort by the score and return the one with the highest score
        scores.max_by { |a| a[0] }
      end

      def crossref_item_scoring(resource, item)
        return [0.0, item] unless resource&.title&.present? && item&.[]('title')&.present?

        # Compare the titles using the Amatch NLP library
        amatch = item['title'].first.pair_distance_similar(resource.title)
        # quarter weight for matching journal title
        if resource.journal.present? && item['container-title']&.first&.present?
          amatch += 0.25 * resource.journal.title.pair_distance_similar(item['container-title'].first)
        end
        names = resource.authors.map { |a| { first: a.author_first_name, last: a.author_last_name } }
        orcids = resource.authors.map(&:author_orcid).reject(&:blank?).map(&:downcase)
        # If authors are available compare them as well, for half weight
        amatch += 0.5 * crossref_author_scoring(names, orcids, item['author']) if item['author'].present? && (names.present? || orcids.present?)
        item['provenance_score'] = item['score']
        item['score'] = amatch
        [amatch, item]
      end

      def crossref_author_scoring(names, orcids, authors)
        amatch = 0.0
        each = 1.to_f / authors.length

        scores = authors.map do |author|
          # An ORCID match is stronger than a name match
          next 1.0 if author['ORCID'].present? && orcids.include?(author['ORCID']&.downcase)
          next 0.0 unless author['family'].present?

          names_to_compare = names.select { |h| h[:last]&.downcase&.include?(author['family']&.downcase) }
          next 0.0 if names_to_compare.empty?

          name_scores = names_to_compare.map do |name|
            "#{name[:first]} #{name[:last]}".downcase.pair_distance_similar("#{author['given']} #{author['family']}".downcase)
          end
          name_scores.max
        end
        return 0.0 unless scores.any? { |v| v > 0.9 }

        scores.each { |v| amatch += each * v }
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
