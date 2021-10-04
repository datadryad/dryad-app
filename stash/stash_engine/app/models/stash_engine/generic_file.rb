require 'zaru'
require 'cgi'
require 'stash/download/file_presigned' # to import the Stash::Download::Merritt exception
require 'stash/download' # for the thing that prevents character mangling in http.rb library
require 'http'

module StashEngine
  class GenericFile < ApplicationRecord
    belongs_to :resource, class_name: 'StashEngine::Resource'
    has_one :frictionless_report, dependent: :destroy
    amoeba do
      enable
      propagate
    end

    scope :deleted_from_version, -> { where(file_state: :deleted) }
    scope :newly_created, -> { where("file_state = 'created' OR file_state IS NULL") }
    scope :present_files, -> { where("file_state = 'created' OR file_state IS NULL OR file_state = 'copied'") }
    scope :url_submission, -> { where('url IS NOT NULL') }
    scope :file_submission, -> { where('url IS NULL') }
    scope :with_filename, -> { where('upload_file_name IS NOT NULL') }
    scope :errors, -> { where('url IS NOT NULL AND status_code <> 200') }
    scope :validated, -> { where('(url IS NOT NULL AND status_code = 200) OR url IS NULL') }
    scope :validated_table, -> { present_files.validated.order(created_at: :desc) }
    scope :tabular_files, -> {
      present_files.where(upload_content_type: 'text/csv')
        .or(present_files.where('upload_file_name LIKE ?', '%.csv'))
        .or(present_files.where(upload_content_type: 'application/vnd.ms-excel'))
        .or(present_files.where('upload_file_name LIKE ?', '%.xls'))
        .or(present_files.where(upload_content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'))
        .or(present_files.where('upload_file_name LIKE ?', '%.xlsx'))
        .or(present_files.where(upload_content_type: 'application/json'))
        .or(present_files.where('upload_file_name LIKE ?', '%.json'))
    }
    enum file_state: %w[created copied deleted].map { |i| [i.to_sym, i] }.to_h
    enum digest_type: %w[md5 sha-1 sha-256 sha-384 sha-512].map { |i| [i.to_sym, i] }.to_h

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

    # returns the latest version number in which this filename was created
    def version_file_created_in
      return resource.stash_version if file_state == 'created' || file_state.blank?

      sql = <<-SQL
             SELECT versions.*
               FROM stash_engine_generic_files uploads
                    JOIN stash_engine_resources resource
                      ON uploads.resource_id = resource.id
                    JOIN stash_engine_versions versions
                      ON resource.id = versions.resource_id
              WHERE uploads.type = '#{self.class}'
                AND resource.identifier_id = ?
                AND uploads.upload_file_name = ?
                AND uploads.file_state = 'created'
           ORDER BY versions.version DESC
              LIMIT 1;
      SQL

      Version.find_by_sql([sql, resource.identifier_id, upload_file_name]).first
    end

    # figures out how to delete file based on previous state
    def smart_destroy!
      # see if it's on the file system and destroy it if it's there
      s3_key = calc_s3_path
      Stash::Aws::S3.delete_file(s3_key: s3_key) if !s3_key.blank? && Stash::Aws::S3.exists?(s3_key: s3_key)

      if in_previous_version?
        # destroy any others of this filename in this resource
        self.class.where(resource_id: resource_id, upload_file_name: upload_file_name).where('id <> ?', id).destroy_all
        # and mark to remove from merritt
        update(file_state: 'deleted')
      else
        # remove all of this filename for this resource from the database
        FrictionlessReport.where(generic_file_id: self.id).destroy_all
        self.class.where(resource_id: resource_id, upload_file_name: upload_file_name).destroy_all
      end

      resource.reload
    end

    # We need to know state from last resource version if any.  It may have both deleted and created last time, which really
    # means created last time.
    def in_previous_version?
      prev_res = resource.previous_resource
      return false if prev_res.nil?

      prev_file = self.class.where(resource_id: prev_res.id, upload_file_name: upload_file_name).order(id: :desc).first
      return false if prev_file.nil? || prev_file.file_state == 'deleted'

      true # otherwise it existed last version because file state is created, copied or nil (nil is assumed to be copied)
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

    def set_checking_status
      @report = FrictionlessReport.create(generic_file_id: id, status: 'checking')
    end

    def validate_frictionless
      result = download_file
      if result.instance_of?(HTTP::Error)
        @report.update(status: 'error')
        return
      end
      result = write_tempfile(result)
      if result.instance_of?(Errno::ENOENT)
        @report.update(status: 'error')
        return
      end
      result = call_frictionless(result)
      # Add 'report' top level key that is required for calling
      # React frictionless-components
      result = clean_frictionless_json(result)

      begin
        result_hash = { report: JSON.parse(result) }
        if validation_error(result_hash[:report])
          @report.update(report: result_hash.to_json, status: 'error')
          logger.error("Some error occurred calling frictionless. See database for report_id #{@report.id}")
          return
        end
        status = if validation_issues_not_found(result_hash)
                   'noissues'
                 else
                   'issues'
                 end
        @report.update(report: result_hash.to_json, status: status)
      rescue JSON::ParserError => e
        @report.update(report: '{}', status: 'error')
        logger.error("Unknown error calling frictionless on generic file #{id} for resource #{resource.id} -- #{e}")
      end
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

    def download_file
      http = HTTP.use(
        normalize_uri: { normalizer: Stash::Download::NORMALIZER }
      ).timeout(connect: 10, read: 10).follow(max_hops: 10)
      dl_url = url || direct_s3_presigned_url
      begin
        http.get(dl_url)
      rescue HTTP::Error => e
        logger.error("Error downloading file: #{e.message}")
        e
      end
    end

    def write_tempfile(result)
      # It's required file to have valid tabular extension for frictionless to return
      # correct validation report
      tempfile = Tempfile.new([upload_file_name, set_extension], Rails.root.join('tmp'), binmode: true)
      tempfile.write(result.body.to_s)
      tempfile.rewind
      tempfile
    rescue Errno::ENOENT => e
      logger.error("Error writing to file: #{e.message}")
      e
    end

    def set_extension
      return '.csv' if (upload_file_name.last(4) == '.csv') || (upload_content_type == 'text/csv')
      return '.xls' if (upload_file_name.last(4) == '.xls') || (upload_content_type == 'application/vnd.ms-excel')
      return '.xlsx' if (upload_file_name.last(5) == '.xlsx') ||
        (upload_content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

      '.json' if (upload_file_name.last(5) == '.json') || (upload_content_type == 'application/json')
    end

    def call_frictionless(file)
      # this captures output from the second command on errors, but not the first which gets ignored if it doesn't work
      # in some of our environments that aren't Ashley's Amazon setup.  May change if she can find other way to set environment.
      cmd = "eval \"$(pyenv init -)\" 2>/dev/null; frictionless validate --path #{file.path} --json 2>&1"
      result = `#{cmd}`
      logger.debug("Frictionless validation:\n  #{cmd}\n  #{result}")
      file.close!
      result
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
