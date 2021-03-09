require 'zaru'
require 'cgi'
require 'stash/download/file_presigned' # to import the Stash::Download::Merritt exception
require 'stash/download' # for the thing that prevents character mangling in http.rb library

module StashEngine
  class FileUpload < ApplicationRecord
    belongs_to :resource, class_name: 'StashEngine::Resource'
    has_many :download_histories, class_name: 'StashEngine::DownloadHistory', dependent: :destroy

    include StashEngine::Concerns::ModelUploadable
    # mount_uploader :uploader, FileUploader # it seems like maybe I don't need this since I'm doing so much manually

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

    # http://<merritt-url>/d/<ark>/<version>/<encoded-fn> is an example of the URLs Merritt takes
    def merritt_url
      domain, ark = resource.merritt_protodomain_and_local_id
      return '' if domain.nil?

      "#{domain}/d/#{ark}/#{resource.stash_version.merritt_version}/#{ERB::Util.url_encode(upload_file_name)}"
    end

    # the Merritt URL to query in order to get the information on the presigned URL
    def merritt_presign_info_url
      raise 'Filename may not be blank when creating presigned URL' if upload_file_name.blank?

      # The gsub below ensures and number signs get double-encoded because otherwise Merritt cuts them off early.
      # We can remove the workaround if it changes in Merritt at some point in the future.

      domain, local_id = resource.merritt_protodomain_and_local_id
      "#{domain}/api/presign-file/#{local_id}/#{resource.stash_version.merritt_version}/" \
          "producer%2F#{ERB::Util.url_encode(upload_file_name.gsub('#', '%23'))}?no_redirect=true"
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

  end
end
