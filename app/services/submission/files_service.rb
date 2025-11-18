module Submission
  class FilesService
    attr_reader :file, :resource

    def initialize(file)
      @file = file
      @resource = file.resource
    end

    def copy_file
      case file.file_state
      when 'created'
        Rails.logger.info(" -- created file moving to permanent store #{file.upload_file_name} -- #{file.s3_staged_path}")
        if file.url && !s3.exists?(s3_key: file.s3_staged_path)
          copy_external_to_permanent_store
        else
          copy_to_permanent_store
        end
      when 'copied'
        # Files aren't actually copied, we just reference the file from the previous version of the dataset
        Rails.logger.info(" -- copied file #{file.upload_file_name}")
      when 'deleted'
        # Files aren't actually deleted, we just don't migrate the file description to future versions of the dataset
        Rails.logger.info(" -- deleted file #{file.upload_file_name}")
      else
        message = "Unable to determine what to do with file #{file.upload_file_name}"
        Rails.logger.error(message)
        raise StandardError, message
      end
    end

    private

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def copy_to_permanent_store
      staged_bucket = APP_CONFIG[:s3][:bucket]
      staged_key = file.s3_staged_path
      permanent_bucket = APP_CONFIG[:s3][:merritt_bucket]
      permanent_key = "v3/#{file.s3_staged_path}"
      Rails.logger.info("file #{file.id} #{staged_bucket}/#{staged_key} ==> #{permanent_bucket}/#{permanent_key}")

      # SKIP uploading the file again if
      #   it exists on permanent store
      #   it has the same size
      # in case a previous job uploaded the file but failed on generating checksum
      if !permanent_s3.exists?(s3_key: permanent_key) || !permanent_s3.size(s3_key: permanent_key) == file.upload_file_size
        s3.copy(from_bucket_name: staged_bucket, from_s3_key: staged_key,
                to_bucket_name: permanent_bucket, to_s3_key: permanent_key,
                size: file.upload_file_size)
      else
        Rails.logger.info("file copy skipped #{file.id} ==> #{permanent_bucket}/#{permanent_key} already exists")
      end

      update = { storage_version_id: resource.id }
      update.merge!(calculate_digest(s3, staged_key))
      file.update(update)
    end

    def copy_external_to_permanent_store
      permanent_bucket = APP_CONFIG[:s3][:merritt_bucket]
      permanent_key = "v3/#{file.s3_staged_path}"

      # SKIP uploading the file again if
      #   it exists on permanent store
      #   it has the same size
      # in case a previous job uploaded the file but failed on generating checksum
      if !permanent_s3.exists?(s3_key: permanent_key) || !permanent_s3.size(s3_key: permanent_key) == file.upload_file_size
        # Copy the file from the URL directly to permanent storage
        s3_perm = Stash::Aws::S3.new(s3_bucket_name: permanent_bucket)
        chunk_size = get_chunk_size(file.upload_file_size)

        input_size = 0
        digest_type = 'sha-256'
        sums = Stash::Checksums.new([digest_type])
        algorithm = sums.get_algorithm(digest_type).new

        Rails.logger.info("file #{file.id} #{file.url} ==> #{permanent_bucket}/#{permanent_key}")
        s3_perm.object(s3_key: permanent_key).upload_stream(part_size: chunk_size, storage_class: 'INTELLIGENT_TIERING') do |write_stream|
          write_stream.binmode
          read_stream = Down.open(file.url, rewindable: false)
          chunk = read_stream.read(chunk_size)
          chunk_num = 1
          cycle_time = Time.now
          while chunk.present?
            write_stream << chunk
            input_size += chunk.length
            Rails.logger.info("file #{file.id} chunk #{chunk_num} size #{chunk.length} ==> #{input_size} (#{Time.now - cycle_time})")
            cycle_time = Time.now
            algorithm.update(chunk)
            chunk = read_stream.read(chunk_size)
            chunk_num += 1
          end
        end

        update = { storage_version_id: resource.id }
        if file.digest.nil?
          raise "Error generating file checksum (#{file.upload_file_name})" if input_size != file.upload_file_size

          update[:digest_type] = digest_type
          update[:digest] = algorithm.hexdigest
          update[:validated_at] = Time.now.utc
        end
      else
        Rails.logger.info("file copy skipped #{file.id} ==> #{permanent_bucket}/#{permanent_key} already exists")
      end

      update = { storage_version_id: resource.id }
      update.merge!(calculate_digest(permanent_s3, permanent_key))
      file.update(update)
    end

    def calculate_digest(s3_connection, file_path)
      return {} if file.digest.present?

      update_info = {}

      Rails.logger.info("generating checksum for #{file.id} ==> #{s3_connection.s3_bucket}/#{file_path} copied from url")
      digest_type = 'sha-256'
      digest_input = s3_connection.presigned_download_url(s3_key: file_path)
      sums = Stash::Checksums.get_checksums([digest_type], digest_input)
      raise "Error generating file checksum (#{file.upload_file_name})" if sums.input_size != file.upload_file_size

      update_info[:digest_type] = digest_type
      update_info[:digest] = sums.get_checksum(digest_type)
      update_info[:validated_at] = Time.now.utc
      update_info
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    def get_chunk_size(size)
      # AWS transfers allow up to 10,000 parts per multipart upload, with a minimum of 5MB per part.
      return 250 * 1024 * 1024 if size > 300_000_000_000
      return 30 * 1024 * 1024 if size > 100_000_000_000
      return 10 * 1024 * 1024 if size > 10_000_000_000

      5 * 1024 * 1024
    end

    def s3
      @s3 ||= Stash::Aws::S3.new
    end

    def permanent_s3
      @permanent_s3 ||= Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
    end
  end
end
