require 'addressable'
require 'cgi'
require 'stash/aws/s3'

# rubocop:disable Style/MixinUsage
# this drops in a couple methods and makes "def filesize(bytes, decimal_points = 2)" available
# to output digital storage sizes
#
include StashEngine::ApplicationHelper
# rubocop:enable Style/MixinUsage

# rubocop:disable Metrics/ClassLength

module StashDatacite
  module Resource

    # an error with a little information about page and id in addition to message, mostly a struct
    # Some items such as name may have more than one field so IDs array, but we probably just focus on first
    class ErrorItem
      attr_accessor :message, :page, :ids
      def initialize(message:, page:, ids:)
        @message = message
        @page = page
        @ids = ids
      end

      def display_message
        url = Addressable::URI.parse(@page)
        url.query_values = (url.query_values || {}).merge({ display_validation: true })
        url_str = "#{url}##{@ids&.first}"
        @message.gsub('{', "<a href=\"#{url_str}\">").gsub('}', '</a>')
      end
    end

    class DatasetValidations
      # this page displays specific validation information
      # contains a message for each, a link for the page to look at and an id for the field with a problem when possible
      def initialize(resource:)
        @resource = resource
      end

      def url_help
        Rails.application.routes.url_helpers
      end

      def metadata_page(resource)
        url_help.metadata_entry_pages_find_or_create_path(resource_id: resource.id)
      end

      def readme_page(resource)
        url_help.prepare_readme_resource_path(id: resource.id)
      end

      def files_page(resource)
        url_help.upload_resource_path(id: resource.id)
      end

      # the metadata entry items are:
      # title, abstract, article_id/doi for journal article, full_author name, author affiliation for all,
      # author email for the first author
      #
      # for the files page:
      # files that haven't validated, errors uploading, too many files, too big of size

      def errors
        err = []
        err << article_id
        err << title
        err << authors
        err << research_domain
        err << funder
        err << abstract
        err << subjects

        err << s3_error_uploads
        err << url_error_validating
        err << over_file_count
        err << over_files_size
        err << data_required

        err.flatten
      end

      # this is a shorter list used by curators
      def loose_errors
        err = []
        err << title
        err << authors
        err << s3_error_uploads
        err << url_error_validating

        err.flatten
      end

      def article_id
        err = []

        if @resource.identifier.import_info != 'other' && @resource.identifier.publication_name.blank?
          err << ErrorItem.new(message: 'Fill in the {journal of the related publication}',
                               page: metadata_page(@resource),
                               ids: ['publication'])
        end

        journal = " from #{@resource.identifier.publication_name}" if @resource.identifier.publication_name.present?

        primary_article = @resource.related_identifiers.where(work_type: 'primary_article').first
        if @resource.identifier.import_info == 'published' && (
                      primary_article.nil? || primary_article.related_identifier.blank? || !primary_article.valid_doi_format?
                    )
          err << ErrorItem.new(message: "Fill in {a correctly formatted DOI} for the article#{journal}",
                               page: metadata_page(@resource),
                               ids: %w[primary_article_doi])
        elsif @resource.identifier.import_info == 'manuscript' && @resource.identifier.manuscript_number.blank?
          err << ErrorItem.new(message: "Fill in the {manuscript number} for the article#{journal}",
                               page: metadata_page(@resource),
                               ids: ['msId'])
        end
        err
      end

      def title
        if @resource.title.blank?
          return ErrorItem.new(message: 'Fill in a {dataset title}', page: metadata_page(@resource), ids: ["title__#{@resource.id}"])
        elsif nondescript_title?
          return ErrorItem.new(
            message: 'Use a {descriptive title} so your dataset can be discovered. Your title is not specific to your dataset.',
            page: metadata_page(@resource),
            ids: ["title__#{@resource.id}"]
          )
        end

        []
      end

      def authors
        temp_err = []
        @resource.authors.each_with_index do |author, idx|

          if author.author_first_name.blank? || author.author_last_name.blank?
            temp_err << ErrorItem.new(message: "Fill #{(idx + 1).ordinalize} author's {first and last name}",
                                      page: metadata_page(@resource),
                                      ids: ["author_first_name__#{author.id}", "author_last_name__#{author.id}"])
          end

          affil = author.affiliation || StashDatacite::Affiliation.new # there is always an affiliation this way
          # below gets rid of the annoying asterisk that go into end of this string, too bad names aren't atomic
          next unless (affil.long_name || '').gsub(/\*$/, '').blank?

          temp_err << ErrorItem.new(message: "Fill #{(idx + 1).ordinalize} author's {institutional affiliation}",
                                    page: metadata_page(@resource),
                                    ids: ["instit_affil__#{author.id}"])
        end

        unless @resource&.owner_author&.author_email.present?
          temp_err << ErrorItem.new(message: "Fill in {submitting author's email}",
                                    page: metadata_page(@resource),
                                    ids: ["author_email__#{@resource&.owner_author&.id}"])
        end

        temp_err
      end

      def research_domain
        domain_require_date = '2021-12-20'
        if @resource.subjects.fos.blank? && @resource.identifier.created_at > domain_require_date
          return ErrorItem.new(message: 'Fill in a {research domain}',
                               page: metadata_page(@resource),
                               ids: ["fos_subjects__#{@resource.id}"])
        end
        []
      end

      def subjects
        subjects_require_date = '2023-06-07'
        if @resource.subjects.non_fos.count < 3 && @resource.identifier.created_at > subjects_require_date
          return ErrorItem.new(message: 'Fill in at least three {keywords}',
                               page: metadata_page(@resource),
                               ids: ['keyword_ac'])
        end
        []
      end

      def funder
        funder_require_date = '2022-04-14'
        if (@resource.contributors.where(contributor_type: 'funder').blank? ||
          @resource.contributors.where(contributor_type: 'funder').first.contributor_name.blank?) &&
           @resource.identifier.created_at > funder_require_date &&
           @resource.identifier.pub_state == 'unpublished'
          return ErrorItem.new(message: 'Fill in a {funder}. Check "No funding received" if there is no funder associated with the dataset.',
                               page: metadata_page(@resource),
                               ids: ['funder_fieldset'])
        end
        []
      end

      def abstract
        unless @resource.descriptions.where(description_type: 'abstract').where.not(description: [nil, '']).count.positive?
          return ErrorItem.new(message: 'Fill in the {abstract}',
                               page: metadata_page(@resource),
                               ids: ['abstract_label'])
        end
        []
      end

      def s3_error_uploads
        return [] if @resource.submitted?

        files = @resource.generic_files.newly_created.file_submission
        errored_uploads = []
        files.each do |f|
          errored_uploads.push(f.upload_file_name) unless Stash::Aws::S3.exists?(s3_key: f.calc_s3_path)
        end

        return [] if errored_uploads.empty?

        msg = '{Check that the following file(s) have uploaded}:<br/><br/>' \
              "#{errored_uploads.map { |i| CGI.escapeHTML(i) }.join('<br/>')}<br/><br/>" \
              'If this state persists for more than a few minutes, please remove and upload the file(s) again.'

        ErrorItem.new(message: msg,
                      page: files_page(@resource),
                      ids: ['filelist_id'])
      end

      def url_error_validating
        # error if has url and not a 200 status code
        files = @resource.generic_files.newly_created.errors.map(&:upload_file_name)

        return [] if files.empty?

        msg = '{Check that the URLs associated with the following files are available and publicly viewable}:<br/><br/>' \
              "#{files.map { |i| CGI.escapeHTML(i) }.join('<br/>')}<br/><br/>" \
              'URLs for deposit need to be publicly accessible and self-contained objects.  For example, ' \
              'adding an HTML file will only retrieve the HTML and not all referenced images or other assets.'

        ErrorItem.new(message: msg,
                      page: files_page(@resource),
                      ids: ['filelist_id'])
      end

      def over_file_count
        return [] unless @resource.generic_files.present_files.count > APP_CONFIG.maximums.files

        ErrorItem.new(message: "{Please limit the number of files to #{APP_CONFIG.maximums.files}} " \
                               'or package your files in a container such as a zip archive',
                      page: files_page(@resource),
                      ids: ['filelist_id'])
      end

      def over_files_size
        errors = []

        if @resource.data_files.present_files.sum(:upload_file_size) > APP_CONFIG.maximums.merritt_size
          errors << ErrorItem.new(message: "Data uploads are limited to #{filesize(APP_CONFIG.maximums.merritt_size, 0)}. " \
                                           '{Remove some data files to proceed}.',
                                  page: files_page(@resource),
                                  ids: ['filelist_id'])
        end

        if @resource.software_files.present_files.sum(:upload_file_size) > APP_CONFIG.maximums.zenodo_size
          errors << ErrorItem.new(message: "Software uploads are limited to #{filesize(APP_CONFIG.maximums.zenodo_size, 0)}. " \
                                           '{Remove some software files to proceed}.',
                                  page: files_page(@resource),
                                  ids: ['filelist_id'])
        end

        if @resource.supp_files.present_files.sum(:upload_file_size) > APP_CONFIG.maximums.zenodo_size
          errors << ErrorItem.new(message: "Supplemental uploads are limited to #{filesize(APP_CONFIG.maximums.zenodo_size, 0)}. " \
                                           '{Remove some supplemental files to proceed}.',
                                  page: files_page(@resource),
                                  ids: ['filelist_id'])
        end

        errors
      end

      def data_required
        errors = []

        readme_md_require_date = '2022-09-28'
        readme_require_date = '2021-12-20'

        if @resource.identifier.created_at > readme_md_require_date
          unless readme_md_files.count.positive? ||
            @resource.descriptions.where(description_type: 'technicalinfo').where.not(description: [nil, '']).count.positive?
            errors << ErrorItem.new(message: '{Include a README} to describe your dataset.',
                                    page: readme_page(@resource),
                                    ids: ['readme_editor'])
          end
        elsif @resource.identifier.created_at > readme_require_date && readme_files.blank?
          errors << ErrorItem.new(message: '{Include a README} to describe your dataset.',
                                  page: readme_page(@resource),
                                  ids: ['readme_editor'])
        end

        unless contains_data?
          errors << ErrorItem.new(message: 'Include at least one data file in your submission. ' \
                                           '{Add some data files to proceed}.',
                                  page: files_page(@resource),
                                  ids: ['filelist_id'])
        end

        errors
      end

      private

      def nondescript_title?
        dict = ['raw', 'data', 'dataset', 'dryad', 'fig', 'figure', 'figures', 'table', 'tables', 'file', 'supp', 'suppl',
                'supplement', 'supplemental', 'extended', 'supplementary', 'supporting', 'et al']
        regex = dict.join('|')
        remainder = @resource.title.gsub(/[^a-z0-9\s]/i, '').gsub(/(#{regex}|s\d|f\d|t\d)\b/i, '').strip
        remainder.split.size < 3
      end

      # Checks for existing data files, Dryad is a data repository and shouldn't be used only as a way to deposit in Zenodo
      # There must be at least one file *other than* the README file.
      def contains_data?
        @resource.data_files.present_files.where("UPPER(upload_file_name) NOT LIKE 'README%'").count.positive?
      end

      def readme_files
        @resource.data_files.present_files.where("UPPER(upload_file_name) LIKE 'README%'")
      end

      def readme_md_files
        @resource.data_files.present_files.where(upload_file_name: 'README.md')
      end

    end
  end
end

# rubocop:enable Metrics/ClassLength
