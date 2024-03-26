namespace :checksums do
  desc 'Download and validate files against their digests'
  task validate_files: :environment do
    today = Time.now.utc
    p "Validating file digests #{today}"
    StashEngine::DataFile
      .where(file_state: 'created').where('validated_at is null or validated_at < ?', 60.days.ago)
      .where.not(digest: nil).find_each do |f|
      p "   Validating file id #{f.id}"
      sums = Stash::Checksums.get_checksums([f.digest_type], f.s3_permanent_presigned_url)
      checksum = sums.get_checksum(f.digest_type)
      size = sums.input_size
      if size == f.upload_file_size && checksum == f.digest
        f.validated_at = today
        f.save
      else
        p '    File cannot be validated; possible corruption!'
        StashEngine::UserMailer.file_validation_error(f).deliver_now
      end
    rescue StandardError => e
      p "    Exception! #{e.message}"
      next

    end
  end

  desc 'Generate new checksums for incorrect duplicates'
  task recreate_digests: :environment do
    today = Time.now.utc
    p "Recreating file digests #{today}"
    StashEngine::DataFile.where(file_state: 'created').where(digest: 'checksum_regen_required').find_each do |f|
      p "   Regenerating checksum for file id #{f.id}"
      digest_type = 'sha-256'
      sums = Stash::Checksums.get_checksums([digest_type], f.s3_permanent_presigned_url)
      checksum = sums.get_checksum(digest_type)
      size = sums.input_size
      if size == f.upload_file_size
        f.digest_type = digest_type
        f.digest = checksum
        f.validated_at = today
        f.save
      else
        p '    Error generating file checksum; possible corruption!'
        StashEngine::UserMailer.file_validation_error(f).deliver_now
      end
    rescue StandardError => e
      p "    Exception! #{e.message}"
      next

    end
  end

  desc 'Copy checksums to copied files'
  task copy_digests: :environment do
    today = Time.now.utc
    p "Copying file digests #{today}"
    StashEngine::DataFile.where(file_state: 'copied').find_each do |copied|
      created = copied.original_deposit_file
      next if created.digest == copied.digest

      p "   Copying digest from file id #{created.id} to file id #{copied.id}"
      copied.digest = created.digest
      copied.digest_type = created.digest_type
      copied.validated_at = created.validated_at
      copied.save
    rescue StandardError => e
      p "    Exception! #{e.message}"
      next

    end
  end
end
