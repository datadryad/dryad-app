require 'zaru'
require 'cgi'

# rubocop:disable Metrics/ClassLength
module StashEngine
  class FileUpload < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'
    include StashEngine::Concerns::ResourceUpdated
    # mount_uploader :uploader, FileUploader # it seems like maybe I don't need this since I'm doing so much manually

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

    # this is to replace temp_file_path which tells where a file was saved when staged for upload by a user
    def calc_file_path
      return nil if file_state == 'copied' || file_state == 'deleted' # no current file to have a path for

      # the uploads directory is well defined so we can calculate it and don't need to store it
      Rails.root.join('uploads', resource_id.to_s, upload_file_name).to_s
    end

    # returns the latest version number in which this filename was created
    def version_file_created_in
      return resource.stash_version if file_state == 'created' || file_state.blank?
      sql = <<-SQL
             SELECT versions.*
               FROM stash_engine_file_uploads uploads
                    JOIN stash_engine_resources resource
                      ON uploads.resource_id = resource.id
                    JOIN stash_engine_versions versions
                      ON resource.id = versions.resource_id
              WHERE resource.identifier_id = ?
                AND uploads.upload_file_name = ?
                AND uploads.file_state = 'created'
           ORDER BY versions.version DESC
              LIMIT 1;
      SQL

      Version.find_by_sql([sql, resource.identifier_id, upload_file_name]).first
    end

    def digest?
      !digest.blank? && !digest_type.nil?
    end

    # http://<merritt-url>/d/<ark>/<version>/<encoded-fn> is an example of the URLs Merritt takes
    def merritt_url
      domain, ark = resource.merritt_protodomain_and_local_id
      return '' if domain.nil?
      "#{domain}/d/#{ark}/#{resource.stash_version.merritt_version}/#{ERB::Util.url_encode(upload_file_name)}"
    end

    # example
    # http://mrtexpress-stage.cdlib.org/dv/<version>/<ark>/<file pathname>
    def merritt_express_url
      domain, ark = resource.merritt_protodomain_and_local_id
      # the ark is already encoded in the URLs we are given from sword
      return '' if domain.nil? # if domain is nil then something is wrong with the ARK too, likely
      "#{APP_CONFIG.merritt_express_base_url}/dv/#{resource.stash_version.merritt_version}" \
          "/#{CGI.unescape(ark)}/#{ERB::Util.url_encode(upload_file_name)}"
    end

    # This will get rid of a file, either immediately, when not submitted yet, or mark it for deletion when it's submitted to Merritt.
    # We also need to refresh the file list for this resource and check for other files with this same name to be deleted since
    # users find ways to do multiple deletions in the UI (multiple windows or perhaps uploading two files with the same name).
    def smart_destroy!
      files_with_name = FileUpload.where(resource_id: resource_id).where(upload_file_name: upload_file_name)

      # destroy any files for this version and and not yet sent to Merritt, shouldn't have nil, but if so, it's newly created
      files_with_name.where(file_state: ['created', nil]).each do |f|
        ::File.delete(f.calc_file_path) if !calc_file_path.blank? && ::File.exist?(f.calc_file_path)
        f.destroy
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

    # makes list of directories with numbers. not modified for > 7 days, and whose corresponding resource has been successfully submitted
    # this could be handy for doing cleanup and keeping old files around for a little while in case of submission problems
    # currently not used since it would make sense to cron this or something similar
    def self.cleanup_dir_list(uploads_dir = Resource.uploads_dir)
      my_dirs = older_resource_named_dirs(uploads_dir)
      return [] if my_dirs.empty?
      Resource.joins(:current_resource_state).where(id: my_dirs)
        .where("stash_engine_resource_states.resource_state = 'submitted'").pluck(:id)
    end

    def self.older_resource_named_dirs(uploads_dir)
      Dir.glob(File.join(uploads_dir, '*')).select { |i| %r{/\d+$}.match(i) }
        .select { |i| File.directory?(i) }.select { |i| File.mtime(i) + 7.days < Time.new.utc }.map { |i| File.basename(i) }
    end

    def self.sanitize_file_name(name)
      # remove invalid characters from the filename: https://github.com/madrobby/zaru
      sanitized = Zaru.sanitize!(name)

      # remove the delete control character
      # remove some extra characters that Zaru does not remove by default
      # replace spaces with underscores
      sanitized.gsub(/,|;|'|"|\u007F/, '').strip.gsub(/\s+/, '_')
    end
  end
end
# rubocop:enable Metrics/ClassLength
