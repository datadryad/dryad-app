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
require 'byebug'
module StashEngine
  class DataFile < GenericFile
    attr_accessor :skip_total_recalculation
    has_many :container_files, class_name: 'StashEngine::ContainerFile', dependent: :delete_all

    after_commit :recalculate_total, unless: :skip_total_recalculation
    after_commit :resource_file_changes

    def recalculate_total
      StashEngine::Resource.find_by(id: resource.id)&.update(total_file_size: resource.data_files.present_files.sum(:upload_file_size))
    end

    def s3_staged_path
      return nil if %w[copied deleted].include?(file_state) # no current file to have a path for

      "#{resource.s3_dir_name(type: 'data')}/#{upload_file_name}"
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

      bkt_instance = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])

      ark = before_file.resource.merritt_ark
      return nil if ark.blank?

      mrt_version_no.downto(1).each do |vers|
        s3_path = "#{ark}|#{vers}|producer/#{before_file.upload_file_name}"
        return s3_path if bkt_instance.exists?(s3_key: s3_path)
      end

      upload_vers = before_file&.resource&.stash_version
      # also look forward a couple versions in version mismatch cases since it seems the file was sometimes uploaded
      # later to correct problems in later, but the database doesn't reflect that
      if upload_vers.present? && upload_vers&.version != upload_vers&.merritt_version
        (upload_vers.merritt_version + 1).upto(upload_vers.merritt_version + 2) do |vers|
          s3_path = "#{ark}|#{vers}|producer/#{before_file.upload_file_name}"
          return s3_path if bkt_instance.exists?(s3_key: s3_path)

        end
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

      # First, look for the file in the v3 hierarchy
      s3 = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
      permanent_key = "v3/#{f.s3_staged_path}"
      return permanent_key if s3.exists?(s3_key: permanent_key)

      # If it's not in the v3 hierarchy, check in the Merritt/ark hierarchy
      f2 = StashEngine::DataFile.find_merritt_deposit_file(file: f) # find where Merritt has decided to store the file, may be an earlier creation

      return StashEngine::DataFile.mrt_bucket_path(file: f2) unless f2.nil?

      # If it gets here, then Merritt has some edge cases where not all entries are represented in our database file entries.
      # Typically, these are specially migrated legacy Dash datasets with Merritt having multiple versions internally, but
      # Dryad has fewer (like Merritt v3 and Dryad v1 and Merritt versions 1 & 2 are not represented in our database at all)
      StashEngine::DataFile.find_merritt_deposit_path(before_file: f)
    end

    # the permanent storage URL, not the staged storage URL
    def s3_permanent_presigned_url
      bucket = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
      bucket.presigned_download_url(s3_key: s3_permanent_path, filename: download_filename)
    end

    def s3_permanent_presigned_url_inline
      bucket = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
      bucket.presigned_download_url(s3_key: s3_permanent_path)
    end

    def public_download_url
      s3_permanent_presigned_url
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
      s3_key = "#{resource.s3_dir_name(type: 'data')}/#{upload_file_name}"
      Stash::Aws::S3.new.presigned_download_url(s3_key: s3_key, filename: download_filename)
    end

    # the URL we use for replication to zenodo, for software it's always the merritt url, but for software we have the same
    # method but switches between S3 and external URL depending on source
    def zenodo_replication_url
      s3_permanent_presigned_url
    end

    # check if file may be previewed
    def preview_type
      return nil if file_deleted_at
      return nil if download_filename == 'README.md'

      return 'csv' if download_filename.end_with?('.csv', '.tsv') ||
        ['text/csv', 'text/tab-separated-values'].include?(upload_content_type)

      return 'txt' if download_filename.end_with?('.txt', '.md') ||
        upload_content_type == 'text/plain'

      return 'zip' if download_filename.end_with?(*APP_CONFIG.container_file_extensions)

      # Images < 5MB
      return nil if upload_file_size && upload_file_size > 5 * 1024 * 1024

      return 'img' if download_filename.end_with?('.png', '.gif', '.jpg', '.jpeg', '.svg') ||
      ['image/png', 'image/gif', 'image/jpeg', 'image/svg+xml'].include?(upload_content_type)

      # PDF < 1MB
      return nil if upload_file_size && upload_file_size > 1 * 1024 * 1024

      return 'pdf' if download_filename.end_with?('.pdf') || upload_content_type == 'application/pdf'

      nil
    end

    def previewable?
      case preview_type
      when 'zip'
        return true if container_files.present?

        false
      when 'txt', 'csv'
        return true if sniff_file(512)

        false
      when 'img'
        return true if download_filename.end_with?('svg') || ['image/svg+xml'].include?(upload_content_type)
        return false unless (number = sniff_file(4, encode: false))
        return true if number[0, 4] == "\x89PNG".b || number[0, 4] == 'GIF8'.b || number[0, 2] == "\xFF\xD8".b

        false
      when 'pdf'
        true
      else
        false
      end
    end

    # for testing CSV delimiters & file validity
    def sniff_file(bytes = 2048, encode: true)
      # get the presigned URL
      s3_url = nil
      begin
        s3_url = digest? || storage_version_id.present? ? s3_permanent_presigned_url : s3_staged_presigned_url
      rescue HTTP::Error, Stash::Download::S3CustomError => e
        logger.info("Couldn't get presigned for #{inspect}\nwith error #{e}")
      end

      begin
        resp = HTTP.timeout(connect: 10, read: 10).timeout(10).headers('Range' => "bytes=0-#{bytes}").get(s3_url)
        return nil if resp.code > 299

        str = resp.to_s
        if encode
          str = str.force_encoding(str.encoding).encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '')
          return nil unless str.encoding == Encoding::UTF_8
        end

        return str
      rescue HTTP::Error
        logger.info("Couldn't get S3 request for #{inspect}")
      end
      nil
    end

    # gets the S3 presigned URL and loads in only the first 5KB of the text file
    def text_preview
      sniff_file(1024 * 5)
    end

    # gets the S3 presigned URL and loads the content
    def file_content
      # get the presigned URL
      s3_url = nil
      s3_url = s3_permanent_presigned_url_inline if digest? || storage_version_id.present?
      s3_url ||= s3_staged_presigned_url

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
      return unless download_filename&.end_with?(*@container_file_exts)

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

    def resource_file_changes
      return unless file_state.in?(%w[created deleted])

      resource.update(has_file_changes: true)
    end
  end
end
