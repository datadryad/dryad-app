module Stash
  module Import
    class Datacite

      def initialize(resource:, json:)
        @resource = resource
        json = JSON.parse(json) if json.is_a?(String)
        @sm = json
      end

      # populate just a few fields
      # article types accepted are 'primary_article', 'article', 'preprint'
      def populate_pub_update!(work_type = 'primary_article')
        return nil unless @sm.present? && @resource.present?

        populate_publication_name(pub_type: work_type)
        @resource.reload
      end

      # populate the full resource from the datacite metadata
      def populate_resource!(work_type = 'primary_article')
        return unless @sm.present? && @resource.present?

        populate_abstract
        populate_authors
        populate_article_type(article_type: work_type)
        populate_funders
        populate_publication_name(pub_type: work_type)
        populate_title
        populate_subjects
        @resource.save
        @resource.reload
      end

      private

      def populate_abstract
        abstract = @sm['descriptions'].find { |d| d['descriptionType'].downcase == 'abstract' }
        return unless abstract.present?

        desc = @resource.descriptions.first_or_initialize(description_type: 'abstract')
        desc.update(description: abstract['description'])
      end

      def populate_affiliation(author, hash)
        affil_name = hash['affiliation']&.first
        affiliation = StashDatacite::Affiliation.from_long_name(long_name: affil_name, check_ror: true) if affil_name.present?
        affiliation.save if affiliation.present?
        affiliation.authors << author if affiliation.present? && !affiliation.authors.include?(author)
      end

      def populate_orcid(hash)
        return if hash['nameIdentifiers'].empty?

        url = hash['nameIdentifiers'].find { |o| o['nameIdentifierScheme'].downcase == 'orcid' }&.[]('nameIdentifier')

        url&.split('/')&.[](-1)
      end

      def populate_author(hash)
        new_auth = StashEngine::Author.new(
          resource_id: @resource.id,
          author_first_name: hash['givenName'],
          author_last_name: hash['familyName'],
          author_org_name: hash['nameType'] == 'Organizational' ? hash['name'] : nil,
          author_orcid: populate_orcid(hash)
        )
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
        return unless @sm['creators'].present? && @sm['creators'].any?

        @sm['creators'].each do |author|
          populate_author(author)
        end
      end

      # rubocop:disable Naming/AccessorMethodName
      def get_or_new_related_doi
        my_related = @sm['doi']
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
        my_related = @sm['doi']
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
        return if @sm['subjects'].empty?

        proposed_subjs = @sm['subjects'].to_h { |s| [s['subject']&.downcase, s['subject']] }
        existing_subjs = @resource.subjects.non_fos.map { |i| i.subject&.downcase }

        to_add = proposed_subjs.keys - existing_subjs

        to_add.each do |subj|
          # puts items with scheme first because of sql ordering
          subs = StashDatacite::Subject.where(subject: subj).non_fos.order(subject_scheme: :desc)
          sub = if subs.blank?
                  StashDatacite::Subject.create(subject: proposed_subjs[subj]) # create with original case
                else
                  subs.first
                end
          @resource.subjects << sub
        end
      end

      def populate_funders
        return if @sm['fundingReferences'].empty?

        @resource.contributors.where(contributor_type: 'funder', contributor_name: ['', nil]).destroy_all

        @sm['fundingReferences'].each do |f|
          @resource.contributors.find_or_initialize_by(
            contributor_type: 'funder',
            contributor_name: f['funderName'],
            award_number: f['awardNumber'],
            name_identifier_id: f['funderIdentifier'],
            identifier_type: f['funderIdentifierType'].downcase,
            award_uri: f['awardUri'],
            award_title: f['awardTitle']
          )
        end
      end

      def populate_publication_name(pub_type: 'primary_article')
        return unless @sm['publisher'].present?

        datum = StashEngine::ResourcePublication.find_or_initialize_by(resource_id: @resource.id, pub_type: pub_type)
        datum.publication_name = @sm['publisher']
        journal = StashEngine::Journal.find_by_title(@sm['publisher'])
        # If the publication name matches an existing journal, populate/update the ISSN
        # Otherwise, remove existing ISSNs that do not match the imported journal name
        datum.publication_issn = journal.present? ? journal.single_issn : nil
        datum.save
      end

      def populate_title
        return if @sm['titles'].empty?

        title = @sm.dig('titles', 0, 'title')
        @resource.title = ActionController::Base.helpers.sanitize(title, tags: %w[em sub sup i])
      end
    end
  end
end
