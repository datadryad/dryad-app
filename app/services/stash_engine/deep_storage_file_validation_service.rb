# frozen_string_literal: true

module StashEngine
  class DeepStorageFileValidationService
    attr_reader :file

    def initialize(file:, bucket:, region:)
      @file = file
      @bucket = bucket
      @s3 = Aws::S3::Client.new(region: region)
      @key = file.s3_permanent_path
    end

    def validate_file
      head = @s3.head_object(bucket: @bucket, key: @key)
      storage = head.storage_class

      # Request restore if Glacier/Deep Archive
      begin
        if %w[GLACIER DEEP_ARCHIVE GLACIER_IR].include?(storage)
          puts "Requesting restore for #{@key} (Deep Archive)"
          @s3.restore_object(
            bucket: @bucket,
            key: @key,
            restore_request: { days: 2, glacier_job_parameters: { tier: 'Standard' } }
          )
        end
      rescue Aws::S3::Errors::RestoreAlreadyInProgress
        # already restoring
        puts 'Restoring in progress'
      end

      # Wait until restoration is complete
      wait_for_restore
      # Generate checksums
      process_file
    end

    private

    def process_file
      # Download to temp
      temp = "/tmp/#{File.basename(@key)}"
      puts "Downloading #{@key}"
      File.open(temp, 'wb') do |file|
        @s3.get_object(bucket: @bucket, key: @key) do |chunk|
          file.write(chunk)
        end
      end

      sums = Stash::Checksums.get_checksums([file.digest_type], File.open(temp))
      checksum = sums.get_checksum(file.digest_type)
      size = sums.input_size
      if size == file.upload_file_size && checksum == file.digest
        file.validated_at = Time.now.utc
        file.save
        puts ' File validated successfully.'
      else
        puts ' File cannot be validated; possible corruption!'
        StashEngine::UserMailer.deep_archive_file_validation_error(file, @bucket).deliver_now
        false
      end
    end

    def wait_for_restore
      loop do
        resp = @s3.head_object(bucket: @bucket, key: @key)
        storage_class = resp.storage_class
        restore_status = resp.restore

        puts "Checking #{@key} – storage class: #{storage_class}, restore: #{restore_status}"

        # return immediately if not Glacier or Deep Archive
        return if restore_status.nil?
        # return if restore complete
        return if restore_status.include?('ongoing-request="false"')

        puts 'Restore in progress, waiting 20 minutes ...'
        sleep 1200
      end
    end
  end
end
