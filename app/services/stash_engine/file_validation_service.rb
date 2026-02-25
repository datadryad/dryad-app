# frozen_string_literal: true

module StashEngine

  class FileValidationService
    attr_reader :file

    S3_DIGEST_TYPES = {
      'sha256' => 'sha-256',
      'sha-256' => 'sha-256',
      'md5' => 'md5'
    }.freeze

    def initialize(file:)
      @file    = file
    end

    def validate_file
      sums     = Stash::Checksums.get_checksums([file.digest_type], file.s3_permanent_presigned_url)
      checksum = sums.get_checksum(file.digest_type)
      size     = sums.input_size
      if size == file.upload_file_size && checksum == file.digest
        file.validated_at = Time.now.utc
        file.save
      else
        p ' File cannot be validated; possible corruption! '
        StashEngine::UserMailer.file_validation_error(file).deliver_now
      end
    end

    def recreate_digests
      digest_type = 'sha-256'
      sums        = Stash::Checksums.get_checksums([digest_type], file.s3_permanent_presigned_url)
      checksum    = sums.get_checksum(digest_type)
      size        = sums.input_size
      if size == file.upload_file_size
        file.digest_type  = digest_type
        file.digest       = checksum
        file.validated_at = Time.now.utc
        file.save
      else
        p ' Error generating file checksum; possible corruption! '
        StashEngine::UserMailer.file_validation_error(file).deliver_now
      end
    end

    def copy_digests
      return if file.copies.blank?

      file.copies.each do |copy|
        puts "   Copying digest from file id #{file.id} to file id #{copy.id}"
        copy.digest       = file.digest
        copy.digest_type  = file.digest_type
        copy.validated_at = file.validated_at
        copy.upload_file_size = file.upload_file_size
        copy.save
      end
    end

    # Use `force_fetch: true` in order to refresh the existing digest with the S3 value
    # returns `true` if the file already has a digest
    #             OR if the digest was successfully updated with S3 value
    # returns `false` in case of any error
    def fetch_s3_digest(bucket_name: APP_CONFIG[:s3][:merritt_bucket], force_fetch: false)
      return true if file.digest? && !force_fetch

      puts "Fetching S3 digest for file #{file.id} form #{bucket_name}"
      s3 = Stash::Aws::S3.new(s3_bucket_name: bucket_name)

      # check V3 path and also ols Merritt path
      v3_path = file.s3_permanent_path
      ark_path = StashEngine::DataFile.mrt_bucket_path(file: file)

      success = fetch_s3_digest_for_path(path: v3_path, s3: s3)
      fetch_s3_digest_for_path(path: ark_path, s3: s3) unless success
    end

    private

    def fetch_s3_digest_for_path(path:, s3:)
      info = s3.head_object(s3_key: path)

      if info&.metadata
        digest_info = fetch_digest(info.metadata)
        file.update!(digest_info) if digest_info
      else
        puts "   No digest metadata on S3 for file #{file.id}"
        return false
      end

      true
    rescue Aws::S3::Errors::NotFound => e
      puts "   Error fetching S3 data for file #{file.id}: #{e.message}"
      false
    end

    def fetch_digest(metadata)
      S3_DIGEST_TYPES.each do |digest_type|
        digest_info = match_digest(metadata, digest_type)
        return digest_info if digest_info
      end
    end

    def match_digest(metadata, digest_type)
      digest = metadata[digest_type[0]]
      return if digest.nil?

      {
        digest_type: digest_type[1],
        digest: digest
      }
    end
  end
end
