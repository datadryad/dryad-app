# == Schema Information
#
# Table name: stash_engine_generic_files
#
#  id                  :integer          not null, primary key
#  cloud_service       :string(191)
#  compressed_try      :integer          default(0)
#  description         :text(65535)
#  digest              :string(191)
#  digest_type         :string(8)
#  download_filename   :text(65535)
#  file_deleted_at     :datetime
#  file_state          :string(7)
#  original_filename   :text(65535)
#  original_url        :text(65535)
#  status_code         :integer
#  timed_out           :boolean          default(FALSE)
#  type                :string(191)
#  upload_content_type :text(65535)
#  upload_file_name    :text(65535)
#  upload_file_size    :bigint
#  upload_updated_at   :datetime
#  url                 :text(65535)
#  validated_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  resource_id         :integer
#  storage_version_id  :integer
#
# Indexes
#
#  index_stash_engine_generic_files_on_download_filename  (download_filename)
#  index_stash_engine_generic_files_on_file_deleted_at    (file_deleted_at)
#  index_stash_engine_generic_files_on_file_state         (file_state)
#  index_stash_engine_generic_files_on_resource_id        (resource_id)
#  index_stash_engine_generic_files_on_status_code        (status_code)
#  index_stash_engine_generic_files_on_upload_file_name   (upload_file_name)
#  index_stash_engine_generic_files_on_url                (url)
#
require 'zaru'
require 'cgi'
require 'stash/download/file_presigned' # to import the Stash::Download::S3CustomError exception
require 'stash/download' # for the thing that prevents character mangling in http.rb library
require 'http'
require 'aws-sdk-lambda'

module StashEngine
  class GenericFile < ApplicationRecord
    self.table_name = 'stash_engine_generic_files'
    has_paper_trail

    belongs_to :resource, class_name: 'StashEngine::Resource'
    has_one :frictionless_report_record, class_name: 'StashEngine::FrictionlessReport', dependent: :destroy
    has_one :sensitive_data_report_record, class_name: 'StashEngine::SensitiveDataReport', dependent: :destroy

    scope :deleted_from_version, -> { where(file_state: :deleted) }
    scope :without_deleted_files, -> { where(file_deleted_at: nil) }
    scope :newly_created, -> { where("file_state = 'created' OR file_state IS NULL") }
    scope :present_files, -> { where("file_state = 'created' OR file_state IS NULL OR file_state = 'copied'") }
    scope :url_submission, -> { where('url IS NOT NULL') }
    scope :file_submission, -> { where('url IS NULL') }
    scope :with_filename, -> { where('download_filename IS NOT NULL') }
    scope :errors, -> { where('url IS NOT NULL AND status_code <> 200') }
    scope :validated, -> { where('(url IS NOT NULL AND status_code = 200) OR url IS NULL') }
    scope :uploaded, -> { where.not(download_filename: ['README.md', 'DisciplineSpecificMetadata.json'], type: StashEngine::DataFile) }
    scope :valid_url_table, -> { present_files.uploaded.url_submission.validated.order(download_filename: :asc) }
    scope :validated_table, -> { present_files.uploaded.validated.order(download_filename: :asc) }

    scope :tabular_files, -> {
      present_files.where(upload_content_type:
        ['text/csv', 'text/tab-separated-values', 'application/vnd.ms-excel', 'application/json', 'application/xml', 'text/xml',
         'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
        .or(present_files.where("upload_file_name RLIKE '.*\\.(csv|tsv|xls|xlsx|json|xml)$'"))
    }
    scope :scannable_files, -> {
      present_files.where(upload_content_type: ['text/csv', 'text/tab-separated-values', 'text/plain'])
        .or(present_files.where("upload_file_name RLIKE '.*\\.(csv|tsv|txt|log)$'"))
    }
    enum(:file_state, %w[created copied deleted].to_h { |i| [i.to_sym, i] })
    enum(:digest_type, %w[md5 sha-1 sha-256 sha-384 sha-512].to_h { |i| [i.to_sym, i] })

    def frictionless_report
      return frictionless_report_record if file_state == 'created'

      original_deposit_file&.frictionless_report_record
    end

    def sensitive_data_report
      return sensitive_data_report_record if file_state == 'created'

      original_deposit_file&.sensitive_data_report_record
    end

    # display the correct error message based on the url status code
    def error_message
      return '' if url.nil? || status_code == 200

      case status_code
      when 400
        'The URL was not entered correctly. Be sure to use http:// or https:// to start all URLS'
      when 401
        'The URL was not authorized for download.'
      when 403..404
        'The URL was not found.'
      when 410
        'The requested URL is no longer available.'
      when 411
        'URL cannot be downloaded, please link directly to data file'
      when 414
        "The server will not accept the request, because the URL #{url} is too long."
      when 408, 499
        'The server timed out waiting for the request to complete.'
      when 409
        "You've already added this URL in this version."
      when 500..511
        'Encountered a remote server error while retrieving the request.'
      else
        'The given URL is invalid. Please check the URL and resubmit.'
      end
    end

    def digest?
      !digest.blank? && !digest_type.nil?
    end

    # The first "created" file of the same name before this one if this one isn't created.
    # In an ideal world, this would have an exact correspondence to where the item is stored in S3, but we don't live in that world.
    def original_deposit_file
      return nil if file_state == 'deleted' # no current file to have a path for

      return self if file_state == 'created' # if this is the first created file, it's the original deposit file

      resources = resource.identifier.resources.joins(:current_resource_state)
        .where(current_resource_state: { resource_state: 'submitted' })
        .where('stash_engine_resources.id < ?', resource.id)

      # this gets the last time this file was in a previous version in the "created" state ie. the last creation
      self.class.where(resource_id: resources.pluck(:id), upload_file_name: upload_file_name,
                       file_state: 'created').order(id: :desc).first
    end

    # returns the latest version number in which this filename was created
    def version_file_created_in
      return resource.stash_version if file_state == 'created' || file_state.blank?

      sql = <<-SQL
              SELECT versions.*
              FROM stash_engine_generic_files uploads
              JOIN stash_engine_resources resource
                ON uploads.resource_id = resource.id
                AND resource.deleted_at IS NULL
              JOIN stash_engine_versions versions
                ON resource.id = versions.resource_id
                AND versions.deleted_at IS NULL
              WHERE uploads.type = '#{self.class}'
                AND resource.identifier_id = ?
                AND uploads.download_filename = ?
                AND uploads.file_state = 'created'
              ORDER BY versions.version DESC
              LIMIT 1;
      SQL

      Version.find_by_sql([sql, resource.identifier_id, download_filename]).first
    end

    # figures out how to delete file based on previous state
    def smart_destroy!
      # see if it's on the file system and destroy it if it's there
      s3_key = s3_staged_path
      Stash::Aws::S3.new.delete_file(s3_key: s3_key) if !s3_key.blank? && Stash::Aws::S3.new.exists?(s3_key: s3_key)

      # convert to hash so we still have after destroying them
      prev_files = case_insensitive_previous_files.map do |pf|
        { download_filename: pf.download_filename, upload_content_type: pf.upload_content_type }
      end

      # get rid of dependent report
      FrictionlessReport.where(generic_file_id: id).destroy_all
      SensitiveDataReport.where(generic_file_id: id).destroy_all

      # destroy previous state for this filename
      self.class.where(resource_id: resource_id).where('lower(download_filename) = ?', download_filename.downcase).destroy_all

      # now add delete actions for all files with same previous filenames, could be more than 1 possibly with different cases
      prev_files.each do |prev_file|
        self.class.create(
          download_filename: prev_file[:download_filename], upload_file_name: prev_file[:upload_file_name],
          upload_content_type: prev_file[:upload_content_type], resource_id: resource_id, file_state: 'deleted'
        )
      end

      resource.reload
    end

    def case_insensitive_previous_files
      prev_res = resource.previous_resource
      return [] if prev_res.nil?

      # tested to identify duplicates, also of different capitalization (at least on our dev server, may depend on mysql collation)
      self.class.where(resource_id: prev_res.id).where('lower(download_filename) = ?', download_filename.downcase)
        .where.not(file_state: 'deleted').order(id: :desc)
    end

    def in_previous_version?
      prev_files = case_insensitive_previous_files
      return false unless prev_files.count.positive?

      true
    end

    def last_version_file
      self.class.joins(:resource)
        .where(upload_file_name: upload_file_name)
        .where('resource_id < ?', resource_id)
        .where('stash_engine_resources.identifier_id = (SELECT res2.identifier_id FROM stash_engine_resources res2 WHERE res2.id = ?)', resource_id)
        .where(file_state: %i[created copied])
        .order(resource_id: :desc)
        .limit(1).first
    end

    # the URL we use for replication from other source (Presigned or URL) up to Zenodo
    def zenodo_replication_url
      raise 'Override zenodo_replication_url in the model'
    end

    def self.sanitize_file_name(name)
      # remove invalid characters from the filename: https://github.com/madrobby/zaru
      sanitized = Zaru.sanitize!(name)

      # remove the delete control character
      # remove some extra characters that Zaru does not remove by default
      # replace spaces with underscores
      sanitized.gsub(/,|;|'|"|\u007F/, '').strip.gsub(/\s+/, '_')
    end

    def set_checking_status(class_name = FrictionlessReport)
      class_name.create(generic_file_id: id, status: 'checking')
      reload
    end

    def trigger_excel_to_csv
      ExcelToCsvLambdaSenderService.new(self, resource).call
    end

    # Given a (mostly) JSON response from Frictionless, discard anything before the opening
    # brace or after the closing brace, because it is typically a warning message from Python
    # that Frictionless didn't handle properly.
    def clean_frictionless_json(in_str)
      return in_str unless in_str.include?('{') && in_str.include?('}')

      first_brace = in_str.index('{')
      last_brace =  in_str.rindex('}')
      in_str[first_brace..last_brace]
    end

    def uploaded_success_url
      dl_url = s3_staged_presigned_url if file_state == 'created' && storage_version_id.blank?
      dl_url ||= public_download_url
      dl_url ||= url
      dl_url
    end

    def uploaded
      return Stash::Aws::S3.new.exists?(s3_key: s3_staged_path) if file_state == 'created' && url.blank? && s3_staged_path

      uploaded_success_url.present?
    end

    def set_extension
      return '.csv' if (upload_file_name.last(4) == '.csv') || (upload_content_type == 'text/csv')
      return '.xls' if (upload_file_name.last(4) == '.xls') || (upload_content_type == 'application/vnd.ms-excel')
      return '.xlsx' if (upload_file_name.last(5) == '.xlsx') ||
        (upload_content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

      '.json' if (upload_file_name.last(5) == '.json') || (upload_content_type == 'application/json')
    end

    def validation_issues_not_found(result)
      result[:report]['tasks'].first['errors'].empty?
    end

    def validation_error(result)
      # See https://framework.frictionlessdata.io/docs/references/errors-reference/
      # for an extensive list of all possible error. Note that there are the errors
      # specific to the validation of a tabular file and the errors for another reason.
      # This method test for errors others than the validation errors.
      !result['errors'].empty?
    end
  end
end
