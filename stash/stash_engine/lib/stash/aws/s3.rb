require 'aws-sdk-s3'

module Stash
  module Aws
    class S3

      def self.write_to_s3(file_path:, contents:)
        puts "XXXX ZZZZZZZ #{file_path}"
        puts "XXXX ZZZZZZZ #{contents}"
        object = s3_bucket.object(file_path)
        object.put(body: contents)
      end

      def self.presigned_download_url(file_path)
        object = s3_bucket.object(file_path)
        object.presigned_url(:get, expires_in: 1.day.to_i)
      end

      class << self
        private

        def s3_resource
          @@s3_resource ||= ::Aws::S3::Resource.new(region: APP_CONFIG[:s3][:region],
                                                    access_key_id: APP_CONFIG[:s3][:key],
                                                    secret_access_key: APP_CONFIG[:s3][:secret])
        end

        def s3_bucket
          @@s3_bucket ||= s3_resource.bucket(APP_CONFIG[:s3][:bucket])
        end
      end
    end
  end
end
