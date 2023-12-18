namespace :checksums do
  desc 'Download and validate files against their digests'
  task validate_files: :environment do
    today = Time.now.utc
    p "Validating file digests #{today}"
    StashEngine::DataFile.where(file_state: 'created').where('validated_at is null or validated_at < ?',
                                                             60.days.ago).where.not(digest: nil).each do |f|
      p "   Validating file id #{f.id}"
      sums = Stash::Checksums.get_checksums([f.digest_type], f.s3_permanent_presigned_url)
      checksum = sums.get_checksum(f.digest_type)
      size = sums.input_size
      if size == f.upload_file_size && checksum == f.digest
        f.validated_at = today
        f.save
      else
        p '    File cannot be validated; possible corruption!'
      end
    rescue StandardError => e
      p "    Exception! #{e.message}"
      next

    end
  end
end
