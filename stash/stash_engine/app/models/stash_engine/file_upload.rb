require 'zaru'
require 'cgi'
require 'stash/download/file_presigned' # to import the Stash::Download::Merritt exception
require 'stash/download' # for the thing that prevents character mangling in http.rb library

# rubocop:disable Metrics/ClassLength
module StashEngine
  class FileUpload < ApplicationRecord
    belongs_to :resource, class_name: 'StashEngine::Resource'
    has_many :download_histories, class_name: 'StashEngine::DownloadHistory', dependent: :destroy

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

    # the Merritt URL to query in order to get the information on the presigned URL
    def merritt_presign_info_url
      domain, local_id = resource.merritt_protodomain_and_local_id
      "#{domain}/api/presign-file/#{local_id}/#{resource.stash_version.merritt_version}/" \
          "producer%2F#{ERB::Util.url_encode(upload_file_name)}?no_redirect=true"
    end

    # this will do the http request to Merritt to get the presigned URL, putting here instead of other classes since it gets
    # reused in a few places.  If we move to a different repo this will need to change.
    #
    # If you use this method, you need to rescue the HTTP::Error and Stash::Download::Merritt errors if you don't want them raised
    # rubocop:disable Metrics/AbcSize
    def s3_presigned_url
      raise Stash::Download::MerrittError, "Tenant not defined for resource_id: #{resource&.id}" if resource&.tenant.blank?

      http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
        .timeout(connect: 30, read: 30).timeout(60).follow(max_hops: 2)
        .basic_auth(user: resource.tenant.repository.username, pass: resource.tenant.repository.password)

      r = http.get(merritt_presign_info_url)

      return r.parse.with_indifferent_access[:url] if r.status.success?

      raise Stash::Download::MerrittError,
            "Merritt couldn't create presigned URL for #{merritt_presign_info_url}\nHttp status code: #{r.status.code}"
    end
    # rubocop:enable Metrics/AbcSize

    # example
    # http://mrtexpress-stage.cdlib.org/dv/<version>/<ark>/<file pathname>
    def merritt_express_url
      domain, ark = resource.merritt_protodomain_and_local_id
      # the ark is already encoded in the URLs we are given from sword
      return '' if domain.nil? # if domain is nil then something is wrong with the ARK too, likely

      # the slash is being double-encoded and normally shouldn't be present, except in a couple of one-off datasets that we regret.
      "#{APP_CONFIG.merritt_express_base_url}/dv/#{resource.stash_version.merritt_version}" \
          "/#{CGI.unescape(ark)}/#{ERB::Util.url_encode(upload_file_name).gsub('%252F', '%2F')}"
    end

    def smart_destroy!
      # see if it's on the file system and destroy it if it's there
      cfp = calc_file_path
      ::File.delete(cfp) if !cfp.blank? && ::File.exist?(cfp)

      if in_previous_version?
        # destroy any others of this filename in this resource
        self.class.where(resource_id: resource_id, upload_file_name: upload_file_name).where('id <> ?', id).destroy_all
        # and mark to remove from merritt
        update(file_state: 'deleted')
      else
        # remove all of this filename for this resource from the database
        self.class.where(resource_id: resource_id, upload_file_name: upload_file_name).destroy_all
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

    # We need to know state from last resource version if any.  It may have both deleted and created last time, which really
    # means created last time.
    def in_previous_version?
      prev_res = resource.previous_resource
      return false if prev_res.nil?

      prev_file = FileUpload.where(resource_id: prev_res.id, upload_file_name: upload_file_name).order(id: :desc).first
      return false if prev_file.nil? || prev_file.file_state == 'deleted'

      true # otherwise it existed last version because file state is created, copied or nil (nil is assumed to be copied)
    end
  end
end
# rubocop:enable Metrics/ClassLength
