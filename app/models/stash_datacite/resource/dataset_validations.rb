require 'addressable'
require 'cgi'
require 'stash/aws/s3'

# rubocop:disable Style/MixinUsage
# this drops in a couple methods and makes "def filesize(bytes, decimal_points = 2)" available
# to output digital storage sizes
#
include StashEngine::ApplicationHelper
# rubocop:enable Style/MixinUsage

module StashDatacite
  module Resource

    class DatasetValidations
      # this page displays specific validation information
      # contains a message for each, a link for the page to look at and an id for the field with a problem when possible
      def initialize(resource:, user: nil)
        @resource = resource
        @user = user
      end

      def url_help
        Rails.application.routes.url_helpers
      end

      def metadata_page(resource)
        url_help.metadata_entry_pages_find_or_create_path(resource_id: resource.id)
      end

      # the metadata entry items are:
      # title, abstract, article_id/doi for journal article, full_author name, author affiliation for all,
      # author email for the first author
      #
      # for the files page:
      # files that haven't validated, errors uploading, too many files, too big of size

      def errors
        import.presence || title.presence || authors.presence || abstract.presence ||
        subjects.presence || funder.presence || type_errors.presence || false
      end

      def type_errors
        if @resource&.resource_type&.resource_type == 'collection'
          collected_datasets.presence || false
        else
          data_required.presence || s3_error_uploads.presence || url_error_validating.presence ||
          over_max.presence || readme_required.presence || false
        end
      end

      def import
        return 'Journal name missing' if %w[manuscript published].include?(@resource.identifier.import_info) &&
          @resource.identifier.publication_name.blank?
        return 'Preprint server missing' if @resource.identifier.import_info == 'preprint' && @resource.identifier.preprint_server.blank?
        return 'Manuscript number missing' if @resource.identifier.import_info == 'manuscript' && @resource.identifier.manuscript_number.blank?

        if @resource.identifier.import_info == 'preprint'
          preprint = @resource.related_identifiers.where(work_type: 'preprint').first
          return 'DOI missing' if preprint.nil? || preprint.related_identifier.blank? || !preprint.valid_doi_format?
        elsif @resource.identifier.import_info == 'published'
          primary_article = @resource.related_identifiers.where(work_type: 'primary_article').first
          return 'DOI missing' if primary_article.nil? || primary_article.related_identifier.blank? || !primary_article.valid_doi_format?
        end
        false
      end

      def title
        return 'Blank title' if @resource.title.blank?
        return 'Nondescriptive title' if nondescript_title?
        return 'All caps title' if @resource.title == @resource.title.upcase

        false
      end

      def authors
        return 'Submitter missing' if @resource.owner_author.nil?
        return 'Submitter email missing' if @resource.owner_author.author_email.blank?
        return 'Names missing' if @resource.authors.any? { |a| a.author_first_name.blank? && a.author_org_name.blank? }
        return 'Affiliations missing' if @resource.authors.any? do |a|
          a.author_org_name.blank? && (a.affiliation.nil? || a.affiliation.long_name.blank?)
        end
        return 'Duplicate author names' if @resource.authors.map(&:author_full_name).uniq.any? do |n|
          @resource.authors.map(&:author_full_name).count(n) > 1
        end
        return 'Duplicate author emails' if @resource.authors.map(&:author_email).uniq.compact_blank.any? do |n|
          @resource.authors.map(&:author_email).count(n) > 1
        end
        return 'Published email missing' if @resource.authors.none?(&:corresp)

        false
      end

      def abstract
        return 'Abstract missing' unless @resource.descriptions.where(description_type: 'abstract').where.not(description: [nil, '']).count.positive?

        false
      end

      def subjects
        subjects_require_date = '2023-06-07'
        domain_require_date = '2021-12-20'
        if @resource.subjects.fos.blank? &&
          (@resource.identifier.publication_date.blank? || @resource.identifier.publication_date > domain_require_date)
          return 'Research domain missing'
        end
        if @resource.subjects.non_fos.count < 3 &&
          (@resource.identifier.publication_date.blank? || @resource.identifier.publication_date > subjects_require_date)
          return 'Subjects missing'
        end

        false
      end

      def funder
        return false if @resource.identifier.publication_date.present?
        return 'Funding missing' if @resource.contributors.where(contributor_type: 'funder').blank? ||
          @resource.contributors.where(contributor_type: 'funder').first.contributor_name.blank?

        false
      end

      def collected_datasets
        return 'No datasets in the collection' if @resource.related_identifiers.where(relation_type: 'haspart').count.zero?

        false
      end

      def data_required
        return 'No data files' unless contains_data?

        false
      end

      def s3_error_uploads
        return false if @resource.submitted?

        files = @resource.generic_files.newly_created.file_submission
        return 'Upload file errors' if files.any? { |f| !Stash::Aws::S3.new.exists?(s3_key: f.s3_staged_path) }

        false
      end

      def url_error_validating
        # error if has url and not a 200 status code
        files = @resource.generic_files.newly_created.errors
        return 'URL file errors' if files.size.positive?

        false
      end

      # rubocop:disable Metrics/AbcSize
      def over_max
        return 'Too many files' if @resource.generic_files.present_files.count > 1000

        files_date = '2025-03-12'
        if (@resource.identifier.publication_date.blank? || @resource.identifier.publication_date > files_date) &&
          (@resource.data_files.present_files.count > APP_CONFIG.maximums.files ||
            @resource.software_files.present_files.count > APP_CONFIG.maximums.files ||
            @resource.supp_files.present_files.count > APP_CONFIG.maximums.files)
          return 'Too many files'
        end

        if !@resource.identifier.new_upload_size_limit
          return 'Over file size limit' if @resource.data_files.present_files.sum(:upload_file_size) > APP_CONFIG.maximums.merritt_size &&
          !@user&.superuser?
        elsif @resource.data_files.present_files.sum(:upload_file_size) > APP_CONFIG.maximums.upload_size
          return 'Over file size limit'
        end

        return 'Over file size limit' if @resource.software_files.present_files.sum(:upload_file_size) > APP_CONFIG.maximums.zenodo_size ||
          @resource.supp_files.present_files.sum(:upload_file_size) > APP_CONFIG.maximums.zenodo_size

        false
      end
      # rubocop:enable Metrics/AbcSize

      def readme_required
        readme_md_require_date = '2022-09-28'
        readme_require_date = '2021-12-20'

        techinfo = @resource.descriptions.where(description_type: 'technicalinfo').where.not(description: [nil, ''])

        no_techinfo = techinfo.empty?
        no_techinfo ||= begin
          JSON.parse(techinfo.first.description)
          true
        rescue StandardError
          false
        end

        if @resource.identifier.publication_date.blank? || @resource.identifier.publication_date > readme_md_require_date
          return 'README file missing' if readme_md_files.count.zero? && no_techinfo
        elsif @resource.identifier.publication_date > readme_require_date
          return 'README file missing' if readme_files.count.zero? && no_techinfo
        end

        false
      end

      def check_payment
        fee = ResourceFeeCalculatorService.new(@resource).calculate({})
        return false if fee[:old_payment_system] || fee[:total].zero?

        "You need to pay a #{fee[:storage_fee_label]} of $#{fee[:total]} in order to submit."
      end

      private

      def nondescript_title?
        dict = ['raw', 'data', 'dataset', 'dryad', 'fig', 'figure', 'figures', 'table', 'tables', 'file', 'supp', 'suppl',
                'supplement', 'supplemental', 'extended', 'supplementary', 'supporting', 'et al',
                'the', 'of', 'for', 'in', 'from', 'to']
        regex = dict.join('|')
        remainder = @resource.title.gsub(/[^a-z0-9\s]/i, '').gsub(/(#{regex}|s\d|f\d|t\d)\b/i, '').strip
        remainder.split.size < 4
      end

      # Checks for existing data files, Dryad is a data repository and shouldn't be used only as a way to deposit in Zenodo
      # There must be at least one file *other than* the README file.
      def contains_data?
        @resource.data_files.present_files.where("UPPER(download_filename) NOT LIKE 'README%'").count.positive?
      end

      def readme_files
        @resource.data_files.present_files.where("UPPER(download_filename) LIKE 'README%'")
      end

      def readme_md_files
        @resource.data_files.present_files.where(download_filename: 'README.md')
      end

    end
  end
end
