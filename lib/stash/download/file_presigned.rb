require 'byebug'
require 'http'

# a significantly simplified class for dealing with Files instead of sending them through our server
# and redirects to a S3 presigned URL
module Stash
  module Download

    class MerrittError < StandardError; end

    class FilePresigned
      attr_reader :cc

      # passing the controller context allows us to do actions the controller would normally do such as redirecting
      # or rendering within the rails context
      def initialize(controller_context:)
        @cc = controller_context
      end

      # file is file from ActiveRecord object
      def download(file:)
        tenant = file&.resource&.tenant
        if file.blank? || tenant.blank?
          cc.render status: 404, plain: 'Not found'
          return
        end

        url = file.merritt_s3_presigned_url

        cc.redirect_to url
      rescue HTTP::Error => e
        raise MerrittError, "HTTP Error while creating presigned URL with Merritt\n" \
                            "#{file.merritt_presign_info_url}\n" \
                            "Original HTTP library error: #{e}\n" \
                            "#{e.full_message}"
      end
    end
  end
end
