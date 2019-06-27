require 'httparty'

module Stash
  module Import
    # rubocop:disable Metrics/ClassLength
    class Crossref

      def initialize(resource:, crossref_json:)
        @resource = resource
        crossref_json = JSON.parse(crossref_json) if crossref_json.is_a?(String)
        @sm = crossref_json # which came form crossref (x-ref) ... see class methods below
      end

      class << self
        def query_by_issn(issn:)
          return nil unless issn.present?

          p HTTParty.get("https://api.crossref.org/journals/#{issn}").body

          p Serrano.journals(query: issn)
          # serrano_response_to_proposed_change(Serrano.journals(query: issn))
        end

        def query_by_doi(identifier:, doi:)
          return nil unless identifier.present? && doi.present?

          resp = Serrano.works(ids: doi)
          return nil unless resp.first.present? && resp.first['message'].present?

          new(resource: identifier.latest_resource, crossref_json: resp.first['message']['indexed'])
        rescue Serrano::NotFound
          nil
        end

        def from_proposed_change(proposed_change:)
          return new(resource: nil, crossref_json: {}) unless proposed_change.is_a?(StashEngine::ProposedChange)
          identifier = StashEngine::Identifier.find(proposed_change.identifier_id)
          date_parts = [proposed_change.publication_date.year, proposed_change.publication_date.month,
                        proposed_change.publication_date.day]
          message = {
            'author' => JSON.parse(proposed_change.authors),
            'published-online' => { 'date-parts' => date_parts },
            'DOI' => proposed_change.publication_doi,
            'publisher' => proposed_change.publication_name,
            'title' => [proposed_change.title]
          }
          new(resource: identifier.latest_resource, crossref_json: message)
        end
      end

      def populate_resource
        populate_abstract
        populate_authors
        populate_cited_by
        populate_funders
        populate_publication_date
        populate_publication_doi
        populate_publication_name
        populate_title
        @resource
      end

      def to_proposed_change
        params = {
          identifier_id: @resource.identifier.id,
          approved: false,
          authors: @sm['author'].to_json,
          provenance: 'crossref',
          publication_date: date_parts_to_date(@sm['published-online']['date-parts']),
          publication_doi: @sm['DOI'],
          publication_name: @sm['publisher'],
          score: @sm['score'],
          title: @sm['title'].first.to_s
        }
        StashEngine::ProposedChange.new(params)
      end

      private

      def known_journals
        excludes = StashEngine::Identifier.publicly_viewable.pluck(:id)
        StashEngine::Identifier.joins(:internal_data).includes(:internal_data).where.not(id: excludes)
          .where('stash_engine_internal_data.data_type = ?', 'publicationName')
      end

      def populate_abstract
        return unless @sm['abstract'].present?
        abstract = @resource.descriptions.first_or_initialize(description_type: 'abstract')
        abstract.description = @sm['abstract']
      end

      def populate_affiliation(author, hash)
        affil_name = (hash['affiliation']&.first ? hash['affiliation'].first['name'] : nil)
        author.affiliation = StashDatacite::Affiliation.from_long_name(affil_name) if affil_name.present?
      end

      def populate_author(hash)
        exists = @resource.authors.where('stash_engine_authors.author_orcid = ? OR ' \
            '(stash_engine_authors.author_first_name = ? AND stash_engine_authors.author_last_name = ?)',
                                         hash['ORCID'], hash['family'], hash['given']).any?
        return if exists

        author = @resource.authors.new(
          author_first_name: hash['given'],
          author_last_name: hash['family'],
          author_orcid: (hash['ORCID'] ? hash['ORCID'].match(/[0-9\-]{19}$/).to_s : nil)
        )
        populate_affiliation(author, hash)
        @resource.authors << author if author.present? && author.valid?
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
        return unless @sm['published-online'].present? && @sm['published-online']['date-parts'].present?
        @resource.publication_date = date_parts_to_date(@sm['published-online']['date-parts'])
        populate_published_status if @resource.publication_date <= Date.today
      end

      def populate_publication_doi
        return unless @sm['DOI'].present?
        datum = @resource.identifier.internal_data.find_or_initialize_by(data_type: 'publicationDOI')
        datum.value = @sm['DOI']
      end

      def populate_publication_name
        return unless @sm['publisher'].present?
        datum = @resource.identifier.internal_data.find_or_initialize_by(data_type: 'publicationName')
        datum.value = @sm['publisher']
      end

      def populate_published_status
        return unless @sm['published-online'].present? && @sm['published-online']['date-parts'].present?
        return if @resource.current_curation_status == 'published'
        @resource.curation_activities << StashEngine::CurationActivity.new(
          user_id: @resource.current_curation_activity.user_id,
          status: 'published',
          note: 'Crossref reported that the related journal has been published'
        )
      end

      def populate_title
        return unless @sm['title'].present? && @sm['title'].any?
        @resource.title = @sm['title'].first
      end

      def date_parts_to_date(parts_array)
        Date.parse(parts_array.join('-'))
      end

      def date_to_date_parts(date)
        date = date.is_a?(Date) ? date : Date.parse(date.to_s)
        [date.year, date.month, date.day]
      end

    end
    # rubocop:enable Metrics/ClassLength
  end
end
