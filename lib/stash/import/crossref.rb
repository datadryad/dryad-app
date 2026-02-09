require 'amatch'
require 'set'
require 'byebug'

require_relative '../../../app/models/stash_engine/proposed_change'

module Stash
  module Import
    # rubocop:disable Metrics/ClassLength
    class Crossref

      include Amatch

      def initialize(resource:, json:)
        @resource = resource
        json = JSON.parse(json) if json.is_a?(String)
        @sm = json # which came from crossref (x-ref) ... see class methods below
      end

      def self.from_proposed_change(proposed_change:)
        return new(resource: nil, json: {}) unless proposed_change.is_a?(StashEngine::ProposedChange)

        identifier = StashEngine::Identifier.find(proposed_change.identifier_id)
        message = {
          'publisher' => proposed_change.publication_name,
          'ISSN' => [proposed_change.publication_issn]
        }
        new(resource: identifier.latest_resource, json: message)
      end

      # populate just a few fields for pub_updater, this isn't as drastic as below and is only for pub updater.
      # to ONLY populate the relationship, use update_type: 'relationship'
      # article types accepted are 'primary_article', 'article', 'preprint'
      def populate_pub_update!(work_type = 'primary_article')
        return nil unless @sm.present? && @resource.present?

        populate_publication_name(pub_type: work_type)
        populate_publication_issn(pub_type: work_type)
        @resource.reload
      end

      # populate the full resource from the crossref metadata, this is for a new record and populating data that the user does, I think
      def populate_resource!(work_type = 'primary_article')
        return unless @sm.present? && @resource.present?

        populate_abstract
        populate_authors
        populate_article_type(article_type: work_type)
        populate_funders
        populate_publication_issn(pub_type: work_type)
        populate_publication_name(pub_type: work_type)
        populate_title
        populate_subjects
        @resource.save
        @resource.reload
      end

      # rubocop:disable Metrics/AbcSize
      def to_proposed_change
        return nil unless @sm.present? && @resource.present?
        # Skip if the identifier already has the change
        return nil if StashEngine::ProposedChange.where(identifier_id: @resource.identifier_id, publication_doi: @sm['DOI']).present?
        # Skip if the resource already has the relation
        return nil if @resource.related_identifiers.where("REGEXP_SUBSTR(`related_identifier`, '(10..+)') = ?", @sm['DOI']).present?

        # Skip if the change does not meet basic checks
        pub_date = date_parts_to_date(publication_date)
        return nil unless @sm['score'].present? && @sm['score'].to_f >= 0.6
        return nil if pub_date&.year&.present? && @resource.identifier.created_at.year - pub_date&.year > 3
        return nil if @resource.authors.count > @sm['author'].count

        params = {
          identifier_id: @resource.identifier_id,
          approved: false,
          rejected: false,
          authors: @sm['author'].first(10).to_json,
          provenance: 'crossref',
          publication_date: pub_date,
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
      # rubocop:enable Metrics/AbcSize

      private

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
          publication_will_change?(proposed_change: proposed_change) ||
          related_identifier_will_change?(proposed_change: proposed_change) ||
          (proposed_change.authors.present? && (auths & @resource.authors).any?) || subjects_changed
      end

      def publication_will_change?(proposed_change:)
        proposed_change.publication_name != @resource.resource_publication&.publication_name ||
          proposed_change.publication_issn != @resource.resource_publication&.publication_issn
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
        affiliation.save if affiliation.present?
        affiliation.authors << author if affiliation.present? && !affiliation.authors.include?(author)
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

        @resource.contributors.where(contributor_type: 'funder', contributor_name: ['', nil]).destroy_all

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

      def populate_publication_name(pub_type: 'primary_article')
        return unless publisher.present?
        # We do not want to overwrite correct journal names with nonstandardized names
        # only update the journal name if the dataset is not already set with this journal ISSN
        return if @sm['ISSN'].present? && @sm['ISSN'].first.present? && @resource.journal.present? &&
          @resource.journal.id == StashEngine::Journal.find_by_issn(@sm['ISSN'].first)&.id

        datum = StashEngine::ResourcePublication.find_or_initialize_by(resource_id: @resource.id, pub_type: pub_type)
        datum.publication_name = publisher
        journal = StashEngine::Journal.find_by_title(publisher)
        # If the publication name matches an existing journal, populate/update the ISSN
        # Otherwise, remove existing ISSNs that do not match the imported journal name
        datum.publication_issn = journal.present? ? journal.single_issn : nil
        datum.save
      end

      def populate_publication_issn(pub_type: 'primary_article')
        return unless @sm['ISSN'].present? && @sm['ISSN'].first.present?

        # Do not change the ISSN if one for this journal is already set
        found = StashEngine::Journal.find_by_issn(@sm['ISSN'].first)
        return if found && @resource.journal&.id == found&.id

        # First look up the ISSN from the journal name (populate_publication_name).
        # If we do not know the ISSN, save it for quarterly checking and addition to our db
        datum = StashEngine::ResourcePublication.find_or_initialize_by(resource_id: @resource.id, pub_type: pub_type)
        datum.publication_issn = @sm['ISSN'].first
        datum.save
      end

      def populate_title
        return unless @sm['title'].present? && @sm['title'].any?

        @resource.title = ActionController::Base.helpers.sanitize(@sm['title'].first, tags: %w[em sub sup i])
      end

      def publication_date
        return @sm['published-online']['date-parts'] if @sm['published-online'].present? && @sm['published-online']['date-parts'].present?
        return @sm['published-print']['date-parts'] if @sm['published-print'].present? && @sm['published-print']['date-parts'].present?
        return @sm['published']['date-parts'] if @sm['published'].present? && @sm['published']['date-parts'].present?

        nil
      end

      def publisher
        pub = @sm['container-title'].presence
        pub ||= @sm.dig('institution', 0, 'name')
        pub ||= @sm['publisher']
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
        bare_ids = @resource.related_identifiers.map { |i| Integrations::Crossref.bare_doi(doi_string: i.related_identifier) }.compact
        bare_target_doi = Integrations::Crossref.bare_doi(doi_string: target_doi)
        bare_ids.include?(bare_target_doi)
      end
    end
    # rubocop:enable Metrics/ClassLength

  end
end
