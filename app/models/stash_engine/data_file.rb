require 'byebug'
module StashEngine
  class DataFile < GenericFile
    has_many :container_files, class_name: 'StashEngine::ContainerFile', dependent: :delete_all

    def s3_staged_path
      return nil if file_state == 'copied' || file_state == 'deleted' # no current file to have a path for

      "#{resource.s3_dir_name(type: 'data')}/#{upload_file_name}"
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
      DataFile.where(resource_id: resources.pluck(:id), upload_file_name: upload_file_name,
                     file_state: 'created').order(id: :desc).first
    end

    # fixes the deposit file for merritt, since they base creating new deposit on sha-256 digest, filename/size
    # rather than an actual re-deposit request. Some people remove files and then re-upload the same file again
    # sometime later
    def self.find_merritt_deposit_file(file:)
      good = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket]).exists?(s3_key: DataFile.mrt_bucket_path(file: file))

      return file if good

      resources = file.resource.identifier.resources.joins(:current_resource_state)
        .where(current_resource_state: { resource_state: 'submitted' })
        .where('stash_engine_resources.id < ?', file.resource.id)

      # this gets the last times this file was in a created state
      dfs = DataFile.where(resource_id: resources.pluck(:id), upload_file_name: file.upload_file_name,
                           file_state: 'created', upload_file_size: file.upload_file_size).order(id: :desc)

      dfs.each do |df|
        good = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket]).exists?(s3_key: DataFile.mrt_bucket_path(file: df))
        return df if good
      end

      nil
    end

    # finds the previous time that a file like this exists in S3 before this one,
    # based only on Merritt version numbers and walking back
    def self.find_merritt_deposit_path(before_file:)
      mrt_version_no = before_file.resource.stash_version.merritt_version - 1
      return nil if mrt_version_no < 1

      bkt_instance = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])

      mrt_version_no.downto(1).each do |vers|
        s3_path = "#{before_file.resource.merritt_ark}|#{vers}|producer/#{before_file.upload_file_name}"
        return s3_path if bkt_instance.exists?(s3_key: s3_path)

      end
      nil
    end

    def self.mrt_bucket_path(file:)
      "#{file.resource.merritt_ark}|#{file.resource.stash_version.merritt_version}|producer/#{file.upload_file_name}"
    end

    # permanent storage rather than staging path
    def s3_permanent_path
      f = original_deposit_file # this is the deposit in the series where this file was last re-uploaded fully by dryad
      return nil if f.nil?

      f2 = DataFile.find_merritt_deposit_file(file: f) # find where Merritt has decided to store the file, may be an earlier creation

      return DataFile.mrt_bucket_path(file: f2) unless f2.nil?

      # If it gets here, then Merritt has some edge cases where not all entries are represented in our database file entries.
      # Typically, these are specially migrated legacy Dash datasets with Merritt having multiple versions internally, but
      # Dryad has fewer (like Merritt v3 and Dryad v1 and Merritt versions 1 & 2 are not represented in our database at all)
      DataFile.find_merritt_deposit_path(before_file: f)
    end

    # the permanent storage URL, not the staged storage URL
    def s3_permanent_presigned_url
      Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
        .presigned_download_url(s3_key: s3_permanent_path)
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
      raise Stash::Download::S3CustomError, "Tenant not defined for resource_id: #{resource&.id}" if resource&.tenant.blank?

      http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
        .timeout(connect: 10, read: 10).timeout(10).follow(max_hops: 2)
        .basic_auth(user: APP_CONFIG[:repository][:username], pass: APP_CONFIG[:repository][:password])

      r = http.get(merritt_presign_info_url)

      return r.parse.with_indifferent_access[:url] if r.status.success?

      raise Stash::Download::S3CustomError,
            "Merritt couldn't create presigned URL for #{merritt_presign_info_url}\nHttp status code: #{r.status.code}"
    end

    # the presigned URL for a file that was "directly" uploaded to Dryad,
    # rather than a file that was indicated by a URL reference
    def s3_staged_presigned_url
      Stash::Aws::S3.new.presigned_download_url(s3_key: "#{resource.s3_dir_name(type: 'data')}/#{original_filename}")
    end

    # the URL we use for replication to zenodo, for software it's always the merritt url, but for software we have the same
    # method but switches between S3 and external URL depending on source
    def zenodo_replication_url
      s3_permanent_presigned_url
    end

    # gets the S3 presigned and loads in only the first few kilobytes of the file rather than all of it and returns
    # the bytes
    def preview_file
      # get the presigned URL
      s3_url = nil
      begin
        s3_url = s3_permanent_presigned_url
      rescue HTTP::Error, Stash::Download::S3CustomError => e
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
      if file_state == 'copied' && last_version_file
        begin
          s3_url = last_version_file.s3_permanent_presigned_url || nil
        rescue HTTP::Error, Stash::Download::S3CustomError => e
          logger.info("Couldn't get presigned for #{inspect}\nwith error #{e}")
        end
      else
        begin
          s3_url = s3_staged_presigned_url
        rescue HTTP::Error, Stash::Download::S3CustomError => e
          logger.info("Couldn't get presigned for #{inspect}\nwith error #{e}")
        end
      end

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
