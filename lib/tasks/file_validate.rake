# :nocov:
namespace :checksums do
  desc 'Download and validate files against their digests'
  task validate_files: :environment do
    Rails.logger.level = :info
    today = Time.now.utc
    index = 0
    puts ''
    puts "Validating file digests #{today}"
    StashEngine::DataFile
      .where(file_state: 'created').where('validated_at is null or validated_at < ?', 60.days.ago)
      .where.not(digest: nil).find_each do |f|
      puts "   Validating file id #{f.id}"
      index += 1
      sleep(2) if index % 100 == 0

      StashEngine::FileValidationService.new(file: f).validate_file
    rescue StandardError => e
      puts "   Exception! #{e.message}"
      next

    end
  end

  desc 'Generate new checksums for incorrect duplicates'
  task recreate_digests: :environment do
    today = Time.now.utc
    index = 0
    puts ''
    puts "Recreating file digests #{today}"
    StashEngine::DataFile.where(file_state: 'created').find_each do |f|
      index += 1
      sleep(2) if index % 100 == 0

      puts "   Regenerating checksum for file id #{f.id}"
      StashEngine::FileValidationService.new(file: f).recreate_digests
    rescue StandardError => e
      puts "   Exception! #{e.message}"
      next
    end
  end

  desc 'Copy checksums to copied files'
  task copy_digests: :environment do
    today = Time.now.utc
    index = 0
    puts ''
    puts "Copying file digests #{today}"
    StashEngine::DataFile.where(file_state: 'copied').find_each do |copied|
      index += 1
      sleep(2) if index % 100 == 0

      StashEngine::FileValidationService.new(file: copied).copy_digests
    rescue StandardError => e
      puts "   Exception! #{e.message}"
      next
    end
  end

  desc 'Copy checksums to copied files'
  task fetch_s3_digests: :environment do
    today = Time.now.utc
    index = 0
    puts ''
    puts "Fetching S3 digests #{today}"
    StashEngine::DataFile.where(file_state: 'created', digest: nil).find_each do |file|
      index += 1
      sleep(2) if index % 100 == 0

      success = StashEngine::FileValidationService.new(file: file).fetch_s3_digest
      puts "   #{success ? 'Succeeded' : 'Failed'}"
    rescue StandardError => e
      puts "   Exception! #{e.message}"
      next
    end
  end
end
# :nocov:
