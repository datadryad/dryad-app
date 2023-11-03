require 'byebug'

module Tasks
  module DownloadCheck
    class S3Check

      attr_accessor :fn, :ark, :mrt_version
      def initialize(file:)
        @bkt_instance = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
        @file = file

        @ark = @file.resource.merritt_ark
        @mrt_version = @file.resource.stash_version.merritt_version
        @fn = @file.upload_file_name
      end

      # returns information about where this file was uploaded in S3 if it doesn't match the expected location
      def check_file
        return nil if @bkt_instance.exists?(s3_key: s3_path(mrt_version: @mrt_version)) # it's in the right place!

        { before: check_before, after: check_after }
      end

      def s3_path(mrt_version:)
        "#{@ark}|#{mrt_version}|producer/#{@fn}"
      end

      def check_before
        return [nil, nil] if @mrt_version < 2

        (@mrt_version - 1).downto(1) do |ver|
          if @bkt_instance.exists?(s3_key: s3_path(mrt_version: ver))
            return [ver, @bkt_instance.size(s3_key: s3_path(mrt_version: ver))]
          end
        end
        [nil, nil]
      end

      def check_after
        last_mrt_version = @file.resource.identifier.resources.order(:id).last.stash_version.merritt_version
        return [nil, nil] if last_mrt_version <= @mrt_version

        (@mrt_version + 1).upto(last_mrt_version) do |ver|
          if @bkt_instance.exists?(s3_key: s3_path(mrt_version: ver))
            return [ver, @bkt_instance.size(s3_key: s3_path(mrt_version: ver))]
          end
        end
        [nil, nil]
      end
    end
  end
end
