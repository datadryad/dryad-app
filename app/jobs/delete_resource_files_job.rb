class DeleteResourceFilesJob < Submission::BaseJob
  include Sidekiq::Worker
  sidekiq_options queue: :deletion, retry: 2, lock: :until_and_while_executing

  def perform(id)
    puts "#{Time.current} - deleting files for resource #{id}"
    resource = StashEngine::Resource.with_deleted.find_by(id: id)
    return if resource.nil?

    # Delete files from temp upload directory, if it exists
    s3_dir = resource.s3_dir_name(type: 'base')
    Stash::Aws::S3.new.delete_dir(s3_key: s3_dir)

    # Delete files from permanent storage, if it exists
    perm_bucket = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
    if resource.download_uri&.include?('ark%3A%2F')
      m = /ark.*/.match(resource.download_uri)
      base_path = CGI.unescape(m.to_s)
      merritt_version = resource.stash_version.merritt_version
      perm_bucket.delete_dir(s3_key: "#{base_path}|#{merritt_version}|producer")
      perm_bucket.delete_dir(s3_key: "#{base_path}|#{merritt_version}|system")
      perm_bucket.delete_file(s3_key: "#{base_path}|manifest")
    else
      perm_bucket.delete_dir(s3_key: "v3/#{s3_dir}")
    end

    # destroy all files as deleted
    resource.generic_files.destroy_all
  end
end
