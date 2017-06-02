module StashEngine
  class FileUpload < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'
    # mount_uploader :uploader, FileUploader # it seems like maybe I don't need this since I'm doing so much manually

    scope :deleted_from_version, -> { where(file_state: :deleted) }
    scope :newly_created, -> { where("file_state = 'created' OR file_state IS NULL") }
    scope :present_files, -> { where("file_state = 'created' OR file_state IS NULL OR file_state = 'copied'") }
    scope :url_submission, -> { where("url IS NOT NULL") }
    scope :file_submission, -> { where("url IS NULL") }
    scope :with_filename, -> { where("upload_file_name IS NOT NULL") }
    scope :errors, -> { where('url IS NOT NULL AND status_code <> 200') }
    scope :validated, -> { where('(url IS NOT NULL AND status_code = 200) OR url IS NULL') }
    scope :validated_table, -> { present_files.validated.order(created_at: :desc) }
    enum file_state: %w(created copied deleted).map { |i| [i.to_sym, i] }.to_h

    # display the correct error message based on the url status code
    def error_message
      return '' if url.nil? || status_code == 200
      case status_code
        when 400
          "The URL was not entered correctly. Be sure to use http:// or https:// to start all URLS"
        when 401
          "The URL was not authorized for download."
        when 403..404
          "The URL was not found."
        when 410
          "The requested URL is no longer available."
        when 414
          "The server will not accept the request, because the URL #{url} is too long."
        when 408, 499
          "The server timed out waiting for the request to complete."
        when 498
          "You've already added this URL in this version."
        when 500..511
          "Encountered a remote server error while retrieving the request."
        else
          "The given URL is invalid. Please check the URL and resubmit."
      end
    end

    # returns the latest version number in which this filename was created
    def version_file_created_in
      return resource.stash_version if file_state == 'created' || file_state.blank?
      sql = <<-EOS
        SELECT v.* FROM
        stash_engine_file_uploads uploads
        JOIN stash_engine_resources resource
        ON uploads.resource_id = resource.id
        JOIN stash_engine_versions v
        ON resource.id = v.`resource_id`
        WHERE resource.`identifier_id` = ?
        AND uploads.upload_file_name = ?
        AND uploads.file_state = 'created'
        ORDER BY v.version DESC
        LIMIT 1;
      EOS

      Version.find_by_sql([sql, resource.identifier_id, upload_file_name]).first
    end
  end
end
