# frozen_string_literal: true

require 'stash/aws/s3'

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
# rubocop:disable Metrics/ClassLength
module StashDatacite
  module Resource
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

        author = @resource.authors.first
        author.author_email.present? ? true : false
      end

      def author_affiliation
        num_authors = @resource.authors.count
        return false if num_authors < 1

        # the completely filled in authors must equal number of authors
        @resource.authors.select { |a| a.affiliation.present? }.count == num_authors
      end

      def abstract
        @resource.descriptions.where(description_type: 'abstract').where.not(description: [nil, '']).count > 0
      end

      # If the journal is filled in, either the manuscript_number or publication_article_doi must be present
      def article_id
        return true unless @resource.identifier.publication_name

        @resource.identifier.manuscript_number || @resource.identifier.publication_article_doi
      end

      def required_completed
        title.to_i + author_affiliation.to_i + author_name.to_i + abstract.to_i + author_email.to_i
      end

      def urls_validated?
        if @resource.data_files.newly_created.errors.count > 0 || @resource.software_files.newly_created.errors.count > 0
          false
        else
          true
        end
      end

      def s3_error_uploads
        files = @resource.generic_files.newly_created.file_submission
        errored_uploads = []
        files.each do |f|
          errored_uploads.push(f.upload_file_name) unless Stash::Aws::S3.exists?(s3_key: f.calc_s3_path)
        end
        errored_uploads
      end

      def over_manifest_file_size?(size_limit)
        @resource.data_files.present_files.sum(:upload_file_size) > size_limit
      end

      def over_manifest_file_count?(count_limit)
        @resource.data_files.present_files.count > count_limit
      end

      def over_version_size?(size_limit)
        @resource.upload_type == :files && @resource.data_files.newly_created.sum(:upload_file_size) > size_limit
      end

      def required_total
        5
      end

      # these are optional (recommended) ones
      def date
        @resource.datacite_dates.where.not(date: [nil, '']).count > 0
      end

      def keyword
        @resource.subjects.non_fos.where.not(subject: [nil, '']).count > 0
      end

      def method
        @resource.descriptions.where(description_type: 'methods').where
          .not(description: [nil, '']).count > 0
      end

      # Disabling Rubocop's stupid rule.  Yeah, I know what I want and I don't want to know if it's a "related_works?"
      # rubocop:disable Naming/PredicateName
      def has_related_works?
        @resource.related_identifiers.where.not(related_identifier: [nil, '']).count > 0
      end

      def has_related_works_dois?
        return false unless has_related_works?

        return true if @resource.related_identifiers.where(related_identifier_type: 'doi').count > 0

        false
      end
      # rubocop:enable Naming/PredicateName

      def good_related_works_formatting?
        filled_related_dois = @resource.related_identifiers.where(related_identifier_type: 'doi').where.not(related_identifier: [nil, ''])

        filled_related_dois.each do |related_id|
          return false unless related_id.valid_doi_format?
        end

        true
      end

      def good_related_works_validation?
        filled_related_dois = @resource.related_identifiers.where(related_identifier_type: 'doi').where.not(related_identifier: [nil, ''])

        filled_related_dois.each do |related_id|
          next if related_id.verified?

          # may need to live-check for older items that didn't go through validation before
          related_id.update(verified: true) if related_id.valid_doi_format? && related_id.live_url_valid? == true

          return false unless related_id.verified?
        end

        true
      end

      def temporal_coverage
        TemporalCoverage.where(resource_id: @resource.id).count > 0
      end

      def optional_completed
        date.to_i + keyword.to_i + method.to_i + has_related_works?.to_i
      end

      def optional_total
        4
      end

      def all_warnings
        messages = []
        error_uploads = s3_error_uploads
        messages << 'Add a dataset title' unless title
        messages << 'Add an abstract' unless abstract
        messages << 'For data related to a journal article, you must supply a manuscript number or DOI' unless article_id
        messages << 'You must have at least one author name and they need to be complete' unless author_name
        messages << 'The first author must have an email supplied' unless author_email
        messages << 'Authors must have affiliations' unless author_affiliation
        messages << 'Fix or remove upload URLs that were unable to validate' unless urls_validated?
        if error_uploads.present?
          messages << 'Some files can not be submitted because they may have had errors uploading. ' \
            'Please re-upload the following files if you still see this error in a few minutes.'
          messages << "Files with upload errors: #{error_uploads.join(',')}"
        end

        # do not require strict related works identifier checking right now
        # messages << 'At least one of your Related Works DOIs are not formatted correctly' unless good_related_works_formatting?
        # messages << 'At least one of your Related Works DOIs did not validate from https://doi.org' unless good_related_works_validation?
        messages
      end

      def relaxed_warnings
        messages = []
        messages << 'Add a dataset title' unless title
        messages << 'You must have at least one author name and they need to be complete' unless author_name
        messages << 'Fix or remove upload URLs that were unable to validate' unless urls_validated?
        messages
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
