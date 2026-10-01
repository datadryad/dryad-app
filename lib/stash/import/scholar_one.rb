module Stash
  module Import
    class ScholarOne
      attr_reader :resource, :metadata, :journal
      def initialize(resource:, manuscript_number:, journal:)
        @resource = resource
        @manuscript_number = manuscript_number
        @journal = journal
        @metadata = Integrations::ScholarOne.new(journal.scholar_one_site_name).manuscript_metadata(@manuscript_number)
      end

      def populate
        return unless @metadata.present? && resource.present?

        populate_abstract
        populate_authors
        populate_publication_name
        populate_funders
        populate_title
        populate_subjects
        populate_research_domains

        resource.save
        resource.reload
      end

      private

      def populate_abstract
        abstract = @metadata['abstractText']
        return unless abstract.present?

        desc = resource.descriptions.first_or_initialize(description_type: 'abstract')
        desc.update(description: abstract)
      end

      def populate_authors
        authors_metadata = Integrations::ScholarOne.new(journal.scholar_one_site_name).authors_metadata(@manuscript_number)
        return unless authors_metadata.present?

        authors_metadata = [authors_metadata] unless authors_metadata.is_a?(Array)
        authors_metadata.each do |author|
          populate_author(author)
        end
      end

      def populate_author(hash)
        new_auth = StashEngine::Author.new(
          resource_id: resource.id,
          author_first_name: hash['authorFirstName'],
          author_last_name: hash['authorLastName'],
          author_order: hash['authorOrderNumber'],
          author_email: hash['authorPrimaryEmailAddress']
        )
        # Try to find an existing author already attached to the resource
        author = resource.authors.select { |a| a == new_auth }.first
        unless author.present?
          resource.authors << new_auth
          author = resource.authors.last
        end

        populate_affiliation(author, hash)
        author.save
      end

      def populate_affiliation(author, hash)
        affiliation_name = hash.dig('departments', 'institution')
        return if affiliation_name.blank?

        affiliation = StashDatacite::Affiliation.from_long_name(long_name: affiliation_name, check_ror: true)
        affiliation.save
        affiliation.authors << author unless affiliation.authors.include?(author)
      end

      def populate_publication_name(pub_type: 'primary_article')
        # We do not want to overwrite correct journal names with nonstandardized names
        # only update the journal name if the dataset is not already set with this journal ISSN
        return if @metadata['journalName'].present? && @metadata['journalDigitalIssn'].present? && @resource.journal.present? &&
          @resource.journal.id == StashEngine::Journal.find_by_issn(@metadata['journalDigitalIssn'])&.id

        datum = StashEngine::ResourcePublication.find_or_initialize_by(resource_id: @resource.id, pub_type: pub_type)
        datum.publication_name = @metadata['journalName']
        datum.publication_issn = @metadata['journalDigitalIssn']
        datum.save
      end

      def populate_subjects
        proposed_subjects = attributes_by_type 'Keywords'
        return if proposed_subjects.empty?

        existing_subjects = resource.subjects.non_fos.map { |i| i.subject&.downcase }
        to_add = proposed_subjects.keys - existing_subjects
        to_add.each do |subj|
          subs = StashDatacite::Subject.where(subject: subj).non_fos.order(subject_scheme: :desc)
          sub = if subs.blank?
                  StashDatacite::Subject.create(subject: proposed_subjects[subj]) # create with original case
                else
                  subs.first
                end
          resource.subjects << sub
        end
      end

      def populate_research_domains
        proposed_subjects = attributes_by_type 'Classification'
        return if proposed_subjects.empty?

        existing_subjects = resource.subjects.fos.map { |i| i.subject&.downcase }
        to_add = proposed_subjects.keys - existing_subjects
        to_add.each do |subj|
          subs = StashDatacite::Subject.where(subject: subj).fos.order(subject_scheme: :desc).first
          next if subs.blank?

          resource.subjects << subs
        end
      end

      def populate_funders
        funders_metadata = @metadata['submissionFunders']
        return if funders_metadata.blank?

        funders_metadata = [funders_metadata] unless funders_metadata.is_a?(Array)
        resource.contributors.where(contributor_type: 'funder', contributor_name: ['', nil]).destroy_all

        funders_metadata.each do |f|
          resource.contributors.find_or_initialize_by(
            contributor_type: 'funder',
            contributor_name: f.dig('fundRefInfo', 'name'),
            name_identifier_id: f.dig('fundRefInfo', 'identifier'),
            identifier_type: 'crossref_funder_id',
            award_number: f['grants']['number'],
            award_title: f['name']
          )
        end
      end

      def populate_title
        return if @metadata['submissionTitle'].empty?

        resource.title = ActionController::Base.helpers.sanitize(@metadata['submissionTitle'], tags: %w[em sub sup i])
      end

      def attributes_by_type(type)
        attrs = @metadata.dig('attributes', 'attribute')
        return if attrs.empty?

        attrs.select { |a| a['attributeTypeName'] == type.to_s }
          .map { |a| a['attributeName'] }
          .index_by(&:downcase)
      end
    end
  end
end
