require 'aws-sdk-s3'

# use example
# require 'stash/aws/s3'
#
# Stash::Aws::S3.new.put(s3_key: 'test01/color.txt', contents: 'Dryad Green is #40841c')
# Stash::Aws::S3.new.exists?(s3_key: 'test01/color.txt')
# Stash::Aws::S3.new.delete_file(s3_key: 'test01/color.txt')

module Stash
  module Aws
    class S3

      attr_reader :s3_bucket

      # By default, use the temporary storage bucket
      def initialize(s3_bucket_name: APP_CONFIG[:s3][:bucket], region: APP_CONFIG[:s3][:region])
        @region = region
        @s3_bucket = s3_resource.bucket(s3_bucket_name)
        @s3_bucket_name = s3_bucket_name
      end

      def put(s3_key:, contents:)
        return unless s3_key && contents

        object = s3_bucket.object(s3_key)
        object.put(body: contents)
      end

      def put_stream(s3_key:, stream:)
        return unless s3_key && stream

        object = s3_bucket.object(s3_key)
        object.upload_stream do |write_stream|
          IO.copy_stream(stream, write_stream)
        end
      end

      def put_file(s3_key:, filename:)
        return unless s3_key && filename

        object = s3_bucket.object(s3_key)
        object.upload_file(filename)
      end

      def exists?(s3_key:)
        obj = s3_bucket.object(s3_key)
        obj.exists?
      end

      def object_versions(s3_key:)
        resp = s3_client.list_object_versions(bucket: @s3_bucket_name, prefix: s3_key)
        resp.versions
      end

      def storage_class(s3_key:)
        head_object(s3_key: s3_key).storage_class
      end

      def size(s3_key:)
        obj = s3_bucket.object(s3_key)
        obj.size
      end

      def presigned_download_url(s3_key:, filename: nil)
        return unless s3_key

        object = s3_bucket.object(s3_key)
        if filename.nil?
          object.presigned_url(:get, expires_in: 1.day.to_i)
        else
          object.presigned_url(:get, expires_in: 1.day.to_i,
                                     response_content_disposition: "attachment; filename=#{URI.encode_www_form_component(filename)}")
        end
      end

      def delete_file(s3_key:)
        return unless s3_key

        object = s3_bucket.object(s3_key)
        object.delete
      end

      def delete_dir(s3_key:)
        return unless s3_key

        s3_key = s3_key.chop if s3_key.ends_with?('/')
        s3_bucket.objects(prefix: "#{s3_key}/").batch_delete!
      end

      def object(s3_key:)
        return unless s3_key

        s3_bucket.object(s3_key)
      end

      def head_object(s3_key:)
        return unless s3_key

        s3_client.head_object(bucket: @s3_bucket_name, key: s3_key)
      end

      def objects(starts_with:)
        return unless starts_with

        s3_bucket.objects(prefix: starts_with)
      end

      def copy(from_bucket_name:, from_s3_key:, to_bucket_name:, to_s3_key:, size:)
        options_hash = {}
        if size > 5_000_000_000
          options_hash[:multipart_copy] = true
          options_hash[:content_length] = size
        end

        bucket = s3_resource.bucket(from_bucket_name)
        object = bucket.object(from_s3_key)
        object.copy_to({ bucket: to_bucket_name, key: to_s3_key, storage_class: 'INTELLIGENT_TIERING' }, options_hash)
      end

      private

      def s3_credentials
        @s3_credentials ||= ::Aws::Credentials.new(APP_CONFIG[:s3][:key], APP_CONFIG[:s3][:secret])
      end

      def s3_client
        @s3_client ||= ::Aws::S3::Client.new(region: @region, credentials: s3_credentials)
      end

      def s3_resource
        @s3_resource ||= ::Aws::S3::Resource.new(client: s3_client)
      end

    end
  end
end
