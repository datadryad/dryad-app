# :nocov:
namespace :checksums do
  desc 'Download and validate files against their digests'
  task validate_files: :environment do
    processing = 500

    Rails.logger.level = :info
    today = Time.now.utc
    index = 0
    puts ''
    puts "Validating file digests #{today}"
    query = StashEngine::DataFile
      .where(file_state: 'created', file_deleted_at: nil)
      .where('validated_at is null or validated_at < ?', 60.days.ago)
      .where.not(digest: nil)

    files = query.order(validated_at: :asc, id: :asc).limit(processing)
    files += query.order(Arel.sql('RAND()')).limit(processing)

    files.uniq.each do |f|
      next if !f.resource || f.resource.current_state == 'in_progress'

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
    StashEngine::DataFile.where(file_state: 'created').where(digest: 'checksum_regen_required').find_each do |f|
      index += 1
      sleep(2) if index % 100 == 0

      puts "   Regenerating checksum for file id #{f.id}"
      StashEngine::FileValidationService.new(file: f).recreate_digests
    rescue StandardError => e
      puts "   Exception! #{e.message}"
      next
    end
  end

  desc 'Generate new checksums for files without a digest'
  task generate_digests: :environment do
    processing = 50

    today = Time.now.utc
    index = 0
    puts ''
    puts "Recreating file digests #{today}"
    query = StashEngine::DataFile.where(
      file_state: 'created',
      file_deleted_at: nil,
      digest: nil
    )
    query.order(id: :desc).limit(processing).each do |file|
      next if !file.resource || file.resource.current_state == 'in_progress'

      index += 1
      sleep(2) if index % 10 == 0

      puts "   Generating checksum for file id #{file.id}"
      StashEngine::FileValidationService.new(file: file).recreate_digests
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
    items = StashEngine::DataFile.where(file_state: 'copied', digest: nil)
    count = items.count
    items.find_each do |copied|
      index += 1
      sleep(2) if index % 100 == 0
      puts "   Parsed #{index}/#{count}" if index % 500 == 0

      StashEngine::FileValidationService.new(file: copied).copy_digests
    rescue StandardError => e
      puts "   Exception! #{e.message}"
      next
    end
  end

  desc 'Copy checksums from S3 to created files'
  task fetch_s3_digests: :environment do
    today = Time.now.utc
    index = 0
    puts ''
    puts "Fetching S3 digests #{today}"
    StashEngine::DataFile.where(file_state: 'created', digest: nil)
      .joins(resource: :identifier)
      .where.not(identifier: { pub_state: 'withdrawn' })
      .find_each do |file|

      next if !file.resource || file.resource.current_state == 'in_progress'

      index += 1
      sleep(2) if index % 100 == 0

      success = StashEngine::FileValidationService.new(file: file).fetch_s3_digest
      puts "   #{success ? 'Succeeded' : 'Failed'}"
    rescue StandardError => e
      puts "   Exception! #{e.message}"
      next
    end
  end

  desc 'Spot checks of secondary file replicas'
  task spot_check_secondary_storage_files: :environment do
    processing = 5

    today = Time.now.utc
    index = 0
    puts ''
    puts "Validating secondary storage checksums for 5 random files #{today}"
    # 5 random files which
    #  have a digest
    #  are not withdrawn
    #  are under 1GB
    #  resource is not in progress
    StashEngine::DataFile
      .where(file_state: 'created', file_deleted_at: nil)
      .where.not(digest: nil)
      .where(upload_file_size: ..1_000_000_000)
      .joins(resource: :identifier)
      .where.not(identifier: { pub_state: 'withdrawn' })
      .order(Arel.sql('RAND()')).limit(100)
      .each do |file|

      next if !file.resource || file.resource.current_state == 'in_progress'

      puts "   Validating secondary storage checksum for file id #{file.id}"
      index += 1
      StashEngine::DeepStorageFileValidationService
        .new(file: file, bucket: 'dryad-assetstore-v3-eu', region: 'eu-central-1')
        .validate_file

      break if index == processing
    rescue StandardError => e
      puts "   Exception! #{e.message}"
      next
    end
    puts 'Done'
  end
end
# :nocov:
