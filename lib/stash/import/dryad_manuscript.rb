# This class does the work of moving metadata from a StashEngine::Manuscript into a StashEngine::Resource
module Stash
  module Import
    class DryadManuscript

      def initialize(resource:, manuscript:)
        @resource = resource
        @manuscript = manuscript
        @metadata = manuscript.metadata
      end

      def populate
        unless @resource.previous_curated_resource.present?
          populate_title
          populate_authors
          populate_abstract
        end
        populate_keywords
      end

      def populate_title
        return if @metadata['ms title'].blank?

        @resource.update(title: @metadata['ms title'])
      end

      def populate_authors
        return if @metadata['ms authors'].blank? || @metadata['ms authors'].first.blank?

        authors = @metadata['ms authors']
        authors.each do |ms_author|
          @resource.authors.create(
            author_first_name: ms_author['given_name'],
            author_last_name: ms_author['family_name'],
            author_orcid: (ms_author['identifierType'] == 'orcid' ? ms_author['identifier'] : nil)
          )
        end
      end

      def populate_abstract
        return if @metadata['abstract'].blank?

        abstract = @resource.descriptions.where(description_type: 'abstract').first_or_create
        abstract.update(description: @metadata['abstract'])
      end

      def populate_keywords
        return if @metadata['keywords'].blank?

        @resource.subjects << @metadata['keywords'].map do |kw|
          StashDatacite::Subject.find_or_create_by(subject: kw)
        end
      end

    end
  end
end
