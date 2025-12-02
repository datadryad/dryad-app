# :nocov:

CHECK_COUNT = 30
namespace :s3_policies do
  # RAILS_ENV=production rake s3_policies:deleted_files_check
  desc 'Download and validate files against their digests'
  task deleted_files_check: :environment do
    puts ''
    puts '--------------------------------'
    puts ''
    puts ''
    puts Time.current
    puts ''

    policy_limit = 1.year.ago
    s3_current = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
    s3_backup = Stash::Aws::S3.new(s3_bucket_name: 'dryad-assetstore-v3-eu', region: 'eu-central-1')

    # file should exist
    # checking multiple files CHECK_COUNT
    puts 'file should only exist in backup bucket'
    existing_limit = policy_limit + 2.day
    files = StashEngine::DataFile
      .deleted
      .where(file_deleted_at: existing_limit..)
      .where.not(upload_file_name: 'README.md')
      .order(file_deleted_at: :asc)
      .first(CHECK_COUNT)

    valid = []
    files.each_with_index do |file, index|
      valid = []
      output = []

      output << "index: #{index}"
      output << "file: #{file.id}"
      file = file.original_deposit_file(with_deleted: true)
      output << "original file: #{file.id}"
      v3_path = "v3/#{file.resource_id}/data/#{file.upload_file_name}"
      ark_path = StashEngine::DataFile.mrt_bucket_path(file: file)

      path = v3_path
      exists = validate_presence(s3_backup, v3_path, log: false)
      if exists
        path = v3_path
      else
        exists = validate_presence(s3_backup, ark_path, log: false)
        path = ark_path if exists
      end
      valid << exists
      output << "#{path} exists in #{s3_backup.s3_bucket.name}: #{exists}"

      deleted = validate_deletion(s3_current, path, log: false)
      valid << deleted
      output << "#{path} is deleted from #{s3_current.s3_bucket.name}: #{deleted}"

      if valid.all?
        puts output.join("\n")
        break
      end
    end

    puts "None of the #{CHECK_COUNT} files checked were successfully validated" unless valid.all?
    puts '----'

    # file should be deleted
    puts 'file should be deleted from all buckets'
    deleted_limit = policy_limit - 2.day
    file = StashEngine::DataFile.deleted
      .where(file_deleted_at: ..deleted_limit)
      .order(file_deleted_at: :desc)
      .first
    puts "file: #{file.id}"
    file = file.original_deposit_file(with_deleted: true)
    puts "original file: #{file.id}"

    v3_path = "v3/#{file.resource_id}/data/#{file.upload_file_name}"
    ark_path = StashEngine::DataFile.mrt_bucket_path(file: file)

    valid << validate_deletion(s3_current, v3_path)
    valid << validate_deletion(s3_current, ark_path)
    # the bellow conditions should be applied if s3_backup deletes the files after 1 year
    # valid << validate_deletion(s3_backup, v3_path)
    # valid << validate_deletion(s3_backup, ark_path)

    StashEngine::NotificationsMailer.s3_lifetime_policy.deliver_now unless valid.all?
  end

  def validate_presence(s3, path, log: true)
    res = s3.object_versions(s3_key: path).any?
    puts "#{path} exists in #{s3.s3_bucket.name}: #{res}" if log
    res
  end

  def validate_deletion(s3, path, log: true)
    res = s3.object_versions(s3_key: path).none?
    puts "#{path} is deleted from #{s3.s3_bucket.name}: #{res}" if log
    res
  end
end
# :nocov:
