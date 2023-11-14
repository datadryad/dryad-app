require 'amatch'
require 'set'
require 'byebug'

require_relative '../../../app/models/stash_engine/proposed_change'

module Stash
  module Import
    # rubocop:disable Metrics/ClassLength
    class Crossref

      include Amatch

      CROSSREF_FIELD_LIST = %w[abstract author container-title DOI funder published-online
                               published-print publisher score title type URL subject].freeze

      def initialize(resource:, crossref_json:)
        @resource = resource
        crossref_json = JSON.parse(crossref_json) if crossref_json.is_a?(String)
        @sm = crossref_json # which came from crossref (x-ref) ... see class methods below
      end

      class << self
        def query_by_doi(resource:, doi:)
          return nil unless resource.present? && doi.present?

          resp = Serrano.works(ids: doi.gsub(/\s+/, ''))
          return nil unless resp.first.present? && resp.first['message'].present?

          new(resource: resource, crossref_json: resp.first['message'])
        rescue Serrano::NotFound, Serrano::InternalServerError
          nil
        end

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

        def from_proposed_change(proposed_change:)
          pro = proposed_change
          return new(resource: nil, crossref_json: {}) unless pro.is_a?(StashEngine::ProposedChange)

          identifier = StashEngine::Identifier.find(proposed_change.identifier_id)
          message = {
            'DOI' => pro.publication_doi,
            'publisher' => pro.publication_name,
            'title' => [pro.title],
            'URL' => pro.url,
            'score' => pro.score,
            'provenance_score' => pro.provenance_score,
            'subject' => (pro.subjects.present? ? JSON.parse(pro.subjects) : [])
          }
          new(resource: identifier.latest_resource, crossref_json: message)
        end

        # returns the bare part (no prefix, just the identifier part) or the full string
        # if it can't parse out a bare identifier from the DOI
        def bare_doi(doi_string:)
          bare_match = %r{^(doi:|https?://dx\.doi\.org/|https?://doi\.org/)(.+)$}
          my_match = doi_string.match(bare_match)
          my_match.present? ? my_match[2] : doi_string
        end
      end

      # populate just a few fields for pub_updater, this isn't as drastic as below and is only for pub updater.
      # to ONLY populate the relationship, use update_type: 'relationship'
      # article types accepted are 'primary_article', 'article', 'preprint'
      def populate_pub_update!(article_type: 'primary_article', update_type: 'metadata')
        return nil unless @sm.present? && @resource.present?

        populate_article_type(article_type: article_type)
        if update_type == 'metadata'
          populate_publication_issn
          populate_publication_name
          populate_subjects
        end

        @resource.reload
      end

      # populate the full resource from the crossref metadata, this is for a new record and populating data that the user does, I think
      def populate_resource!
        return unless @sm.present? && @resource.present?

        populate_abstract
        populate_authors
        populate_article_type(article_type: 'primary_article')
        populate_funders
        populate_publication_issn
        populate_publication_name
        populate_title
        populate_subjects
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
          rejected: false,
          authors: @sm['author'].to_json,
          provenance: 'crossref',
          publication_date: date_parts_to_date(publication_date),
          publication_doi: @sm['DOI'],
          publication_issn: @sm['ISSN']&.first,
          publication_name: publisher.is_a?(Array) ? publisher&.first : publisher,
          score: @sm['score'],
          provenance_score: @sm['provenance_score'],
          title: @sm['title']&.first&.to_s,
          url: @sm['URL'],
          subjects: @sm['subject'].to_json,
          xref_type: @sm['type']
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

          issn = resource.identifier.internal_data.where(data_type: 'publicationISSN').first&.value
          issn = CGI.escape(issn) if issn.present?
          title_query = resource.title&.gsub(/\s+/, ' ')&.strip
          title_query = CGI.escape(title_query)&.gsub(/\s/, '+') if title_query.present?
          author_query = resource.authors.map { |a| a.author_last_name.gsub(/\s+/, ' ')&.strip }
          author_query = author_query.map { |a| CGI.escape(a) }.join('+') if author_query.present?

          [issn, title_query, author_query]
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

      end
      def resource_will_change?(proposed_change:)
        if proposed_change.authors.present?
          json = JSON.parse(proposed_change.authors)
          if json.is_a?(Array) && json.any?
            auths = json.map do |auth|
              StashEngine::Author.new(resource_id: @resource.id, author_orcid: auth['ORCID'],
                                      author_first_name: auth['given'], author_last_name: auth['family'])
            end
          end
        end

        if proposed_change.subjects.present?
          subjects_changed = false
          json = JSON.parse(proposed_change.subjects)
          if json.is_a?(Array) && json.any?
            proposed_subjs = json.to_set(&:downcase)
            existing_subjs = @resource.subjects.non_fos.to_set { |i| i.subject&.downcase }
            subjects_changed = !proposed_subjs.subset?(existing_subjs)
          end
        end

        proposed_change.publication_date != @resource.publication_date ||
          internal_datum_will_change?(proposed_change: proposed_change) ||
          related_identifier_will_change?(proposed_change: proposed_change) ||
          (proposed_change.authors.present? && (auths & @resource.authors).any?) || subjects_changed
      end

      def internal_datum_will_change?(proposed_change:)
        internal_data = @resource.identifier.internal_data
        proposed_change.publication_name != internal_data.select { |d| d.data_type == 'publicationName' }.first&.value ||
          proposed_change.publication_name != internal_data.select { |d| d.data_type == 'publicationISSN' }.first&.value
      end

      def related_identifier_will_change?(proposed_change:)
        related_identifier = @resource.related_identifiers.where(related_identifier_type: 'doi', work_type: 'primary_article').last
        proposed_change.publication_doi != related_identifier&.related_identifier
      end

      def populate_abstract
        return unless @sm['abstract'].present?

        abstract = @resource.descriptions.first_or_initialize(description_type: 'abstract')
        abstract.update(description: @sm['abstract'])
      end

      def populate_affiliation(author, hash)
        affil_name = (hash['affiliation']&.first ? hash['affiliation'].first['name'] : nil)
        affiliation = StashDatacite::Affiliation.from_long_name(long_name: affil_name, check_ror: true) if affil_name.present?
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
        author.author_orcid = hash['ORCID'].match(/[0-9-]{19}$/).to_s if hash['ORCID'].present?
        populate_affiliation(author, hash)
        author.save
      end

      def populate_authors
        return unless @sm['author'].present? && @sm['author'].any?

        @sm['author'].each do |xr_author|
          populate_author(xr_author)
        end
      end

      # rubocop:disable Naming/AccessorMethodName
      def get_or_new_related_doi
        my_related = @sm['URL'] || @sm['DOI']
        return nil if my_related.blank?

        # Use the URL if available otherwise just use the DOI
        @resource.related_identifiers
          .where(related_identifier: StashDatacite::RelatedIdentifier.standardize_doi(my_related),
                 related_identifier_type: 'doi').first || @resource.related_identifiers.new
      end
      # rubocop:enable Naming/AccessorMethodName

      def populate_article_type(article_type:)
        return unless article_type.present? && %w[primary_article article preprint].include?(article_type)

        related = get_or_new_related_doi
        my_related = @sm['URL'] || @sm['DOI']
        return if related.nil? || my_related.nil?

        related.assign_attributes({
                                    related_identifier: StashDatacite::RelatedIdentifier.standardize_doi(my_related),
                                    related_identifier_type: 'doi',
                                    relation_type: 'iscitedby',
                                    work_type: article_type,
                                    verified: true,
                                    hidden: false
                                  })
        related.save!
      end

      def populate_subjects
        return unless @sm['subject'].present?

        json = @sm['subject']
        return unless json.is_a?(Array) && json.any?

        # produces hash with downcase keys and original values
        subj_hsh = json.to_h { |h| [h.downcase, h] }
        proposed_subjs = subj_hsh.keys
        existing_subjs = @resource.subjects.non_fos.map { |i| i.subject&.downcase }

        to_add = proposed_subjs - existing_subjs

        to_add.each do |subj|
          # puts items with scheme first because of sql ordering
          subs = StashDatacite::Subject.where(subject: subj).non_fos.order(subject_scheme: :desc)
          sub = if subs.blank?
                  StashDatacite::Subject.create(subject: subj_hsh[subj]) # create with original case
                else
                  subs.first
                end
          @resource.subjects << sub
        end
      end

      def populate_funders
        return unless @sm['funder'].present? && @sm['funder'].is_a?(Array) && @sm['funder'].any?

        @sm['funder'].each do |xr_funder|
          next if xr_funder['name'].blank?

          if xr_funder['award'].blank?
            @resource.contributors.find_or_initialize_by(contributor_name: xr_funder['name'], contributor_type: 'funder')
            next
          end
          xr_funder['award'].each do |xr_award|
            @resource.contributors.find_or_initialize_by(contributor_name: xr_funder['name'], contributor_type: 'funder', award_number: xr_award)
          end
        end
      end

      def populate_publication_date
        return unless publication_date.present?

        @resource.publication_date = date_parts_to_date(publication_date)
      end

      def populate_publication_issn
        return unless @sm['ISSN'].present? && @sm['ISSN'].first.present?

        # We only want to save the ISSN if we receive one that we already know about. Otherwise,
        # it is likely an alternative ISSN for a journal where we have a different primary ISSN
        # (most journals have separate ISSNs for print, online, linking)
        # In that case, we will save the journal name, and look up the correct ISSN from the name.
        return unless StashEngine::Journal.find_by_issn(@sm['ISSN'].first).present?

        datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: @resource.identifier.id,
                                                                 data_type: 'publicationISSN')
        datum.update(value: @sm['ISSN'].first)
      end

      def populate_publication_name
        return unless publisher.present?

        datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: @resource.identifier.id,
                                                                 data_type: 'publicationName')
        datum.update(value: publisher)

        journal = StashEngine::Journal.find_by_title(publisher)
        return unless journal.present?

        # If the publication name matches an existing journal, populate/update the ISSN
        datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: @resource.identifier.id,
                                                                 data_type: 'publicationISSN')
        datum.update(value: journal.single_issn)
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
        pub = @sm['container-title'].present? ? @sm['container-title'] : @sm['publisher']
        pub.is_a?(Array) ? pub.first : pub
      end

      def date_parts_to_date(parts_array)
        return nil unless parts_array.present? && parts_array.is_a?(Array)

        Date.parse(parts_array.join('-'))
      rescue StandardError
        nil
      end

      def date_to_date_parts(date)
        date = Date.parse(date.to_s) unless date.is_a?(Date)
        [date.year, date.month, date.day]
      rescue StandardError
        nil
      end

      # this is a helper method to detect duplicate reference dois
      def duplicate_reference_doi?(target_doi:)
        bare_ids = @resource.related_identifiers.map { |i| Crossref.bare_doi(doi_string: i.related_identifier) }.compact
        bare_target_doi = Crossref.bare_doi(doi_string: target_doi)
        bare_ids.include?(bare_target_doi)
      end
    end
    # rubocop:enable Metrics/ClassLength

  end
end
