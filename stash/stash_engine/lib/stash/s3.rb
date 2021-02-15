require 'aws-sdk-s3'

# use example
# require 'stash/s3'
# s3 = Stash::S3.new
#
# s3.exists?(directory: 'test01', filename: 'color1_03.png')
#
# s3.destroy(directory: 'test01', filename: 'color1_03.png')

# This file is based on Stash/s3/test.rb in test-s3 branch, we can fix and move further methods in as we need them
#
module Stash
  class S3
    def initialize
      # setting up basics
      @bucket_name = APP_CONFIG[:s3][:bucket]
      s3_credentials = Aws::Credentials.new(APP_CONFIG[:s3][:key], APP_CONFIG[:s3][:secret])
      @s3_client = Aws::S3::Client.new(region: APP_CONFIG[:s3][:region], credentials: s3_credentials)
      @s3_resource = Aws::S3::Resource.new(client: @s3_client)
    end

    def destroy(s3_key:)
      obj = @s3_resource.bucket(@bucket_name).object(s3_key)
      obj.delete
    end

    def exists?(s3_key:)
      obj = @s3_resource.bucket(@bucket_name).object(s3_key)
      obj.exists?
    end
  end
end
