module StashEngine
  class FileUpload < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'
    # mount_uploader :uploader, FileUploader # it seems like maybe I don't need this since I'm doing so much manually

    scope :deleted_from_version, -> { where(file_state: :deleted) }
    scope :newly_created, -> { where("file_state = 'created' OR file_state IS NULL") }
    scope :url_submission, -> { where("url IS NOT NULL") }
    scope :file_submission, -> { where("url IS NULL") }
    scope :with_filename, -> { where("upload_file_name IS NOT NULL") }
    scope :errors, -> { where('url IS NOT NULL AND status_code <> 200') }
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
        when 500..511
          "Encountered a remote server error while retrieving the request."
        else
          "The given URL is invalid. Please check the URL and resubmit."
      end
    end
  end
end
