module Stash
  module Import
    class CrossRef

      include Stash::Organization::Ror

      def initialize(resource:, serrano_message:)
        @resource = resource
        @sm = serrano_message # which came form crossref (x-ref)
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
          if affil_name.present?
            ror_org = find_first_by_ror_name(affil_name)
            author.affiliation = StashDatacite::Affiliation.first_or_create(long_name: affil_name, ror_id: ror_org&.id)
          end
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
  end
end
