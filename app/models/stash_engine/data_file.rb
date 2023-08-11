require 'byebug'
module StashEngine
  class DataFile < GenericFile
    has_many :container_files, class_name: 'StashEngine::ContainerFile', dependent: :delete_all

    def calc_s3_path
      return nil if file_state == 'copied' || file_state == 'deleted' # no current file to have a path for

      "#{resource.s3_dir_name(type: 'data')}/#{upload_file_name}"
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

      if upload_file_name.include?('#')
        # Merritt needs the components double-encoded when there is a '#' in the filename
        "#{domain}/api/presign-file/#{ERB::Util.url_encode(local_id)}/#{resource.stash_version.merritt_version}/" \
          "producer%252F#{ERB::Util.url_encode(ERB::Util.url_encode(upload_file_name))}?no_redirect=true"
      else
        "#{domain}/api/presign-file/#{local_id}/#{resource.stash_version.merritt_version}/" \
          "producer%2F#{ERB::Util.url_encode(upload_file_name)}?no_redirect=true"
      end
    end

    # this will do the http request to Merritt to get the presigned URL, putting here instead of other classes since it gets
    # reused in a few places.  If we move to a different repo this will need to change.
    #
    # If you use this method, you need to rescue the HTTP::Error and Stash::Download::Merritt errors if you don't want them raised
    def merritt_s3_presigned_url
      raise Stash::Download::MerrittError, "Tenant not defined for resource_id: #{resource&.id}" if resource&.tenant.blank?

      http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
        .timeout(connect: 10, read: 10).timeout(10).follow(max_hops: 2)
        .basic_auth(user: APP_CONFIG[:repository][:username], pass: APP_CONFIG[:repository][:password])

      r = http.get(merritt_presign_info_url)

      return r.parse.with_indifferent_access[:url] if r.status.success?

      raise Stash::Download::MerrittError,
            "Merritt couldn't create presigned URL for #{merritt_presign_info_url}\nHttp status code: #{r.status.code}"
    end

    # the presigned URL for a file that was "directly" uploaded to Dryad,
    # rather than a file that was indicated by a URL reference
    def direct_s3_presigned_url
      Stash::Aws::S3.presigned_download_url(s3_key: "#{resource.s3_dir_name(type: 'data')}/#{upload_file_name}")
    end

    # the URL we use for replication to zenodo, for software it's always the merritt url, but for software we have the same
    # method but switches between S3 and external URL depending on source
    def zenodo_replication_url
      merritt_s3_presigned_url
    end

    # gets the S3 presigned and loads in only the first few kilobytes of the file rather than all of it and returns
    # the bytes
    def preview_file
      # get the presigned URL
      s3_url = nil
      begin
        s3_url = merritt_s3_presigned_url
      rescue HTTP::Error, Stash::Download::MerrittError => e
        logger.info("Couldn't get presigned for #{inspect}\nwith error #{e}")
      end

      return nil if s3_url.nil?

      # now try to get actual file by range and return it
      begin
        resp = HTTP.timeout(connect: 10, read: 10).timeout(10).headers('Range' => 'bytes=0-2048').get(s3_url)
        return nil if resp.code > 299

        return resp.to_s
      rescue HTTP::Error
        logger.info("Couldn't get S3 request for preview range for #{inspect}")
      end
      nil
    end

    # gets the S3 presigned and loads the content (for READMEs)
    def file_content
      # get the presigned URL
      s3_url = nil
      begin
        s3_url = file_state == 'copied' && last_version_file && last_version_file&.merritt_s3_presigned_url
      rescue HTTP::Error, Stash::Download::MerrittError => e
        logger.info("Couldn't get presigned for #{inspect}\nwith error #{e}")
      end
      s3_url = merritt_s3_presigned_url if s3_url.nil?
      s3_url = direct_s3_presigned_url if s3_url.nil?

      return nil if s3_url.nil?

      # now try to get actual file by range and return it
      begin
        resp = HTTP.timeout(1000).get(s3_url)

        return nil if resp.code > 299

        return resp.to_s
      rescue HTTP::Error
        logger.info("Couldn't get S3 request for #{inspect}")
      end
      nil
    end

    # This is mostly used to duplicate these files when a new version is created.
    # It will fail getting previous version if the record isn't saved and has no id or resource_id yet.
    def populate_container_files_from_last
      @container_file_exts ||= APP_CONFIG[:container_file_extensions].map { |ext| ".#{ext}" }
      return unless upload_file_name&.end_with?(*@container_file_exts)

      old_files = case_insensitive_previous_files
      return if old_files.empty? || old_files.first.file_state == 'deleted'

      container_files.delete_all # remove any existing container files

      to_insert = old_files.first.container_files.map do |container_file|
        { data_file_id: id, path: container_file.path, mime_type: container_file.mime_type, size: container_file.size }
      end
      StashEngine::ContainerFile.insert_all(to_insert) unless to_insert.blank?
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
