require 'httparty'

module Stash
  module Import
    class Crossref

      def initialize(resource:, serrano_message:)
        @resource = resource
        @proposed_changes = @resource.proposed_changes.find
        @sm = serrano_message # which came form crossref (x-ref) ... see class methods below
      end

      def self.query_by_issn(issn:)
        return nil unless issn.present?

        p HTTParty.get("https://api.crossref.org/journals/#{issn}").body

        p Serrano.journals(query: issn)
        #serrano_response_to_proposed_change(Serrano.journals(query: issn))
      end

      def self.query_by_doi(identifier:, doi:)
        return nil unless identifier.present? && doi.present?

        resp = Serrano.works(ids: doi)
        return nil unless resp.first.present? && resp.first['message'].present?
        return nil unless self.validate_crossref_match(identifier, resp)

        self.new(resource: identifier.latest_resource, serrano_message: resp.first['message']['indexed'])
      rescue Serrano::NotFound
        return nil
      end

      def self.from_proposed_change(identifier:)
        proposed_change = StashDatacite::ProposedChange.where(identifier_id: identifier.id)
        message = {
          'authors': JSON.parse(proposed_change.authors),
          'published-online': { 'date-parts': date_to_date_parts(proposed_change.publication_date) },
          'DOI': proposed_change.publication_doi,
          'publisher': proposed_change.publication_name,
          'title': [proposed_change.title]
        }
        self.new(resource: identifier.latest_resource, serrano_message: message)
      end

      def populate
        populate_abstract
        populate_authors
        populate_cited_by
        populate_funders
        populate_publication_date
        populate_publication_doi
        populate_publication_name
        populate_title
        @resource.save
      end

      def save_changes_for_review
        params = {
          identifier_id: @resource.identifier,
          approved: false,
          approved_by_id: nil,
          authors: @sm['authors'].to_s,
          provenance: 'crossref',
          publication_date: date_parts_to_date(@sm['published-online']['date-parts']),
          publication_doi: @sm['DOI'],
          publication_name: @sm['publisher'],
          score: @sm['score'],
          title: @sm['title'].first.to_s
        }
        StashDatacite::ProposedChange.new(params)
      end

      private

      def self.validate_crossref_match(identifier, response)
        true
      end

      def known_journals
        excludes = StashEngine::Identifier.publicly_viewable.pluck(:id)
        StashEngine::Identifier.joins(:internal_data).includes(:internal_data).where.not(id: excludes)
          .where('stash_engine_internal_data.data_type = ?', 'publicationName')
      end



      def populate_abstract
        return unless @sm['abstract'].present?
        abstract = @resource.descriptions.where(description_type: 'abstract').first_or_initialize
        abstract.description = @sm['abstract']
      end

      def populate_authors
        return unless @sm['author'].present? && @sm['author'].any?
        @sm['author'].each do |xr_author|
          author = @resource.authors.new(
            author_first_name: xr_author['given'],
            author_last_name: xr_author['family'],
            author_orcid: (xr_author['ORCID'] ? xr_author['ORCID'].match(/[0-9\-]{19}$/).to_s : nil)
          )
          affil_name = (xr_author['affiliation']&.first ? xr_author['affiliation'].first['name'] : nil)
          author.affiliation = StashDatacite::Affiliation.from_long_name(affil_name) if affil_name.present?
          exists = @resource.authors.where(author_orcid: author.author.orcid).or
            .where(author_last_name: author.author_last_name, author_first_name: author_first_name).first
          @resource.authors << author if author.present? && author.valid? && exists.blank?
        end
      end

      def populate_cited_by
        return unless @sm['URL'].present?
        @resource.related_identifiers.new(related_identifier: @sm['URL'], related_identifier_type: 'doi', relation_type: 'iscitedby')
      end

      def populate_funders
        funders = []
        @sm['funder'].each do |xr_funder|
          next if xr_funder['name'].blank?
          if xr_funder['award'].blank?
            @resource.contributors.new(contributor_name: xr_funder['name'], contributor_type: 'funder')
            next
          end
          xr_funder['award'].each do |xr_award|
            @resource.contributors.create(contributor_name: xr_funder['name'], contributor_type: 'funder', award_number: xr_award)
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
        datum = @resource.identifier.internal_data.find_or_initialize(data_type: 'publicationDOI')
        datum.value = @sm['DOI']
      end

      def populate_publication_name
        return unless @sm['publisher'].present?
        datum = @resource.identifier.internal_data.find_or_initialize(data_type: 'publicationName')
        datum.value = @sm['publisher']
      end

      def populate_published_status
        return unless @sm['published-online'].present? && @sm['published-online']['date-parts'].present?
        return if @resource.files_published?
        @resource.curation_activities << StashEngine::CurationActivity.new(
          user_id: r.current_curation_activity.user_id,
          status: 'published',
          note: 'Crossref reported that the related journal has been published'
        )
      end

      def populate_title
        return unless @sm['title'].present && @sm['title'].any?
        @resource.title = @sm['title'].first
      end

      def date_parts_to_date(parts_array)
        Date.new(parts_array.join('-'))
      end

      def date_to_date_parts(date)
        date = Date.new(date.to_s)
        [date.year, date.month, date.day]
      end

    end

  end
end
