require 'active_support/concern'

module StashEngine
  module Concerns
    module ModelUploadable

      extend ActiveSupport::Concern

      included do
        scope :deleted_from_version, -> { where(file_state: :deleted) }
        scope :newly_created, -> { where("file_state = 'created' OR file_state IS NULL") }
        scope :present_files, -> { where("file_state = 'created' OR file_state IS NULL OR file_state = 'copied'") }
        scope :url_submission, -> { where('url IS NOT NULL') }
        scope :file_submission, -> { where('url IS NULL') }
        scope :with_filename, -> { where('upload_file_name IS NOT NULL') }
        scope :errors, -> { where('url IS NOT NULL AND status_code <> 200') }
        scope :validated, -> { where('(url IS NOT NULL AND status_code = 200) OR url IS NULL') }
        scope :validated_table, -> { present_files.validated.order(created_at: :desc) }
        enum file_state: %w[created copied deleted].map { |i| [i.to_sym, i] }.to_h
        enum digest_type: %w[adler-32 crc-32 md2 md5 sha-1 sha-256 sha-384 sha-512].map { |i| [i.to_sym, i] }.to_h
      end

      # display the correct error message based on the url status code
      def error_message # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
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

      # This will get rid of a file, either immediately, when not submitted yet, or mark it for deletion when it's submitted to Merritt.
      # We also need to refresh the file list for this resource and check for other files with this same name to be deleted since
      # users find ways to do multiple deletions in the UI (multiple windows or perhaps uploading two files with the same name).
      def smart_destroy!
        files_with_name = self.class.where(resource_id: resource_id).where(upload_file_name: upload_file_name)

        # destroy any files for this version and and not yet sent to Merritt, shouldn't have nil, but if so, it's newly created
        files_with_name.where(file_state: ['created', nil]).each do |fl|
          ::File.delete(fl.calc_file_path) if !fl.calc_file_path.blank? && ::File.exist?(fl.calc_file_path)
          fl.destroy
        end

        # leave only one delete directive for this filename for this resource (ie the first listed file), if there is already
        # a delete directive then it must've been copied at one point from the last resource, so keep one
        files_with_name.where(file_state: %w[deleted copied]).each_with_index do |f, idx|
          if idx == 0
            f.update(file_state: 'deleted')
          else
            f.destroy
          end
        end
        resource.reload
      end

      class_methods do
        def sanitize_file_name(name)
          # remove invalid characters from the filename: https://github.com/madrobby/zaru
          sanitized = Zaru.sanitize!(name)

          # remove the delete control character
          # remove some extra characters that Zaru does not remove by default
          # replace spaces with underscores
          sanitized.gsub(/,|;|'|"|\u007F/, '').strip.gsub(/\s+/, '_')
        end
      end
    end
  end
end
