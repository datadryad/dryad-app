require 'httparty'

module Stash
  module Import
    class Crossref

      def self.query_for_issn(issn:)
        return [] unless issn.present?

        p HTTParty.get("https://api.crossref.org/journals/#{issn}").body

        p Serrano.journals(query: issn)
        #serrano_response_to_proposed_change(Serrano.journals(query: issn))
      end

      def self.query_for_dois(dois:)
        return [] unless dois.present?

p dois

p Serrano.works(ids: dois)

        #serrano_response_to_proposed_change(Serrano.works(ids: dois))
      end

      private

      def known_journals
        excludes = StashEngine::Identifier.publicly_viewable.pluck(:id)
        StashEngine::Identifier.joins(:internal_data).includes(:internal_data).where.not(id: excludes)
          .where('stash_engine_internal_data.data_type = ?', 'publicationName')
      end

      def serrano_response_to_proposed_change(response)
        params = {
          title: response['title']&.first,
          authors: response['author'].to_s
        }
        changes = StashDatacite::ProposedChange.new(params)
      end






      def populate
        populate_title
        populate_authors
        populate_abstract
        populate_funders
        populate_cited_by
      end

      def populate_title
        return if @sm['title'].blank? || @sm['title'].first.blank?
        @resource.update(title: @sm['title'].first)
      end

      # authors may contain given, family , affiliation, ORCID
      def populate_authors
        return if @sm['author'].blank?
        @sm['author'].each do |xr_author|
          author = @resource.authors.create(
            author_first_name: xr_author['given'],
            author_last_name: xr_author['family'],
            author_orcid: (xr_author['ORCID'] ? xr_author['ORCID'].match(/[0-9\-]{19}$/).to_s : nil)
          )
          affil_name = (xr_author['affiliation']&.first ? xr_author['affiliation'].first['name'] : nil)

          # If the affiliation was provided try looking up its ROR id
          author.affiliation = StashDatacite::Affiliation.from_long_name(affil_name) if affil_name.present?
          author.save if affil_name.present?
        end
      end

      def populate_abstract
        return if @sm['abstract'].blank?
        abstract = @resource.descriptions.where(description_type: 'abstract').first_or_create
        abstract.update(description: @sm['abstract'])
      end

      def populate_funders
        return if @sm['funder'].blank?
        # remove any sad blank records
        @resource.contributors.each do |item|
          item.destroy if item.contributor_name.blank? && item.award_number.blank?
        end
        @sm['funder'].each do |xr_funder|
          next if xr_funder['name'].blank?
          if xr_funder['award'].blank?
            @resource.contributors.create(contributor_name: xr_funder['name'], contributor_type: 'funder')
            next
          end
          xr_funder['award'].each do |xr_award|
            @resource.contributors.create(contributor_name: xr_funder['name'], contributor_type: 'funder', award_number: xr_award)
          end
        end
      end

      def populate_cited_by
        return if @sm['URL'].blank?
        @resource.related_identifiers.create(related_identifier: @sm['URL'], related_identifier_type: 'doi', relation_type: 'iscitedby')
      end

    end

    class CrossrefJournal
      attr_accessor :title, :issn, :datasets

      def initialize(name:, issn:)
        @title = name
        @issn = issn
        datasets.each do |dataset|
          identifier = StashEngine::Identifier.joins(:internal_data).includes(:internal_data)
                                              .where(id: dataset, data_type: %w[publicationDOI manuscriptNumber])
          next unless identifier.present?
          @dois = identifier.internal_data.where(data_type: 'publicationDOI').pluck(:value)
          @manuscripts = identifier.internal_data.where(data_type: 'manuscriptNumber').pluck(:value)
        end
      end

      private

      # gather together all of the unique StashEngine::Identifier associated with the Journal
      def datasets
        ids = StashEngine::InternalDatum.where(data_type: 'publicationISSN', value: @issn).pluck(:identifier_id)
        ids << StashEngine::InternalDatum.where(data_type: 'publicationName', value: @name).pluck(:identifier_id)
        ids.uniq
      end
    end

  end
end
