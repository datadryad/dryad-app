# frozen_string_literal: true

# basing this structure on that suggested in http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/

# also
# monkeypatch true and false to_i to be 0 and 1
class FalseClass
  def to_i
    0
  end
end
class TrueClass
  def to_i
    1
  end
end

require 'stash_datacite/author_patch'

module StashDatacite
  module Resource
    # TODO: is this class really necessary? as with Review, seems like we could just patch Resource
    # TODO: and we don't need most of these to return false or 0 when they can just return nil
    class Completions
      def initialize(resource)
        @resource = resource

        # After dev mode autoreloading, ensure Author-Affiliation relation & related methods
        StashDatacite::AuthorPatch.patch! unless StashEngine::Author.method_defined?(:affiliation)
      end

      # these are the required ones and return true/false if completed
      def title
        !@resource.title.blank?
      end

      def institution
        @resource.authors.joins(:affiliations).count > 0
      end

      def data_type
        !@resource.resource_type.nil?
      end

      def author_name
        num_authors = @resource.authors.count
        return false if num_authors < 1
        # the completely filled in authors must equal number of authors
        @resource.authors.names_filled.count == num_authors
      end

      def author_email
        num_authors = @resource.authors.count
        return false if num_authors < 1
        author = @resource.authors.order(created_at: :asc).first
        author.author_email.present? ? true : false
      end

      def author_affiliation
        num_authors = @resource.authors.count
        return false if num_authors < 1
        # the completely filled in authors must equal number of authors
        @resource.authors.affiliation_filled.count == num_authors
      end

      def abstract
        @resource.descriptions.where(description_type: 'abstract').where.not(description: [nil, '']).count > 0
      end

      def required_completed
        title.to_i + author_affiliation.to_i + author_name.to_i + abstract.to_i + author_email.to_i
      end

      def urls_validated?
        if @resource.upload_type == :manifest && @resource.file_uploads.newly_created.errors.count > 0
          false
        else
          true
        end
      end

      def over_manifest_file_size?(size_limit)
        @resource.file_uploads.present_files.sum(:upload_file_size) > size_limit
      end

      def over_manifest_file_count?(count_limit)
        @resource.file_uploads.present_files.count > count_limit
      end

      def over_version_size?(size_limit)
        @resource.upload_type == :files && @resource.file_uploads.newly_created.sum(:upload_file_size) > size_limit
      end

      def required_total
        5
      end

      # these are optional (recommended) ones
      def date
        @resource.datacite_dates.where.not(date: [nil, '']).count > 0
      end

      def keyword
        @resource.subjects.where.not(subject: [nil, '']).count > 0
      end

      def method
        @resource.descriptions.where(description_type: 'methods').where
          .not(description: [nil, '']).count > 0
      end

      # TODO: why is this called 'citation'?
      def citation
        @resource.related_identifiers.where.not(related_identifier: [nil, '']).count > 0
      end

      def optional_completed
        date.to_i + keyword.to_i + method.to_i + citation.to_i
      end

      def optional_total
        4
      end

      def all_warnings # rubocop:disable Metrics/CyclomaticComplexity
        messages = []
        messages << 'Add a dataset title' unless title
        messages << 'Add an abstract' unless abstract
        messages << 'You must have at least one author name and they need to be complete' unless author_name
        messages << 'At least one author must have an email supplied' unless author_email
        messages << 'Authors must have affiliations' unless author_affiliation
        messages << 'Fix or remove upload URLs that were unable to validate' unless urls_validated?
        messages
      end

      def relaxed_warnings
        messages = []
        messages << 'Add a dataset title' unless title
        messages << 'Add an abstract' unless abstract
        messages << 'You must have at least one author name and they need to be complete' unless author_name
        messages << 'Fix or remove upload URLs that were unable to validate' unless urls_validated?
        messages
      end
    end
  end
end
