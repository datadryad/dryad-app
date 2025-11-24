# :nocov:
namespace :s3_policies do
  # RAILS_ENV=production rake s3_policies:deleted_files
  desc 'Download and validate files against their digests'
  task deleted_files: :environment do
    policy_limit = 1.year.ago
    s3_current = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
    s3_storage = Stash::Aws::S3.new(s3_bucket_name: 'dryad-assetstore-v3-eu', region: 'eu-central-1')

    # file should exist
    existing_limit = policy_limit + 2.day
    file = StashEngine::DataFile
             .deleted
             .where(file_deleted_at: existing_limit..)
             .where.not(upload_file_name: 'README.md')
             .order(file_deleted_at: :asc).first
    file = file.original_deposit_file(with_deleted: true)
    path = "v3/#{file.resource_id}/data/#{file.upload_file_name}"
    exists = s3_current.object_versions(s3_key: path).none?
    puts "#{path} is deleted from main storage: #{exists}"
    exists = s3_storage.object_versions(s3_key: path).any?
    puts "#{path} exists in backup storage: #{exists}"


    # file should de deleted
    deleted_limit = policy_limit - 2.day
    file = StashEngine::DataFile.deleted
             .where(file_deleted_at: ..deleted_limit)
             .order(file_deleted_at: :desc)
             .first
    file = file.original_deposit_file(with_deleted: true)
    path = "v3/#{file.resource_id}/data/#{file.upload_file_name}"

    exists = s3_current.object_versions(s3_key: path).none?
    puts "#{path} is deleted from main storage: #{exists}"
    exists = s3_storage.object_versions(s3_key: path).none?
    puts "#{path} is deleted from backup storage: #{exists}"
  end
end
# :nocov:
