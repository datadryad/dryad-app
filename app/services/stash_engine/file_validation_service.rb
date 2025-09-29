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
      created = file.original_deposit_file
      return if created.digest == file.digest

      puts "   Copying digest from file id #{created.id} to file id #{file.id}"
      file.digest       = created.digest
      file.digest_type  = created.digest_type
      file.validated_at = created.validated_at
      file.save
    end

    # Use `force_fetch: true` in order to refresh the existing digest with the S3 value
    # returns `true` if the file already has a digest
    #             OR if the digest was successfully updated with S3 value
    # returns `false` in case of any error
    def fetch_s3_digest(bucket_name: APP_CONFIG[:s3][:merritt_bucket], force_fetch: false)
      return true if file.digest? && !force_fetch

      puts "Fetching S3 digest for file #{file.id}"
      s3 = Stash::Aws::S3.new(s3_bucket_name: bucket_name)
      info = s3.head_object(s3_key: file.s3_permanent_path)

      if info&.metadata
        pp digest_info = fetch_digest(info.metadata)
        file.update!(digest_info) if digest_info
      else
        puts "   No digest metadata on S3 for file #{file.id} on bucket #{bucket_name}"
        return false
      end

      true
    rescue Aws::S3::Errors::NotFound => e
      puts "   Error fetching S3 data for file #{file.id}: #{e.message}"
      false
    end

    private

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
