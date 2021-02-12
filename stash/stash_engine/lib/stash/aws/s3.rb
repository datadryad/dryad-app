require 'aws-sdk-s3'

module Stash
  module Aws
    class S3

      def self.put(file_path:, contents:)
        return unless file_path && contents

        object = s3_bucket.object(file_path)
        object.put(body: contents)
      end

      def self.presigned_download_url(file_path)
        return unless file_path

        object = s3_bucket.object(file_path)
        object.presigned_url(:get, expires_in: 1.day.to_i)
      end

      def self.delete_file(file_path)
        return unless file_path

        object = s3_bucket.object(file_path)
        object.delete
      end

      def self.delete_dir(dir_path)
        return unless dir_path

        dir_path = dir_path.chop if dir_path.ends_with?('/')
        s3_bucket.objects(prefix: "#{dir_path}/").batch_delete!
      end

      class << self
        private

        def s3_resource
          @s3_resource ||= ::Aws::S3::Resource.new(region: APP_CONFIG[:s3][:region],
                                                   access_key_id: APP_CONFIG[:s3][:key],
                                                   secret_access_key: APP_CONFIG[:s3][:secret])
        end

        def s3_bucket
          @s3_bucket ||= s3_resource.bucket(APP_CONFIG[:s3][:bucket])
        end
      end
    end
  end
end
