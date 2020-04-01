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

      # file is file_upload from ActiveRecord
      def download(file:)
        tenant = file&.resource&.tenant
        if file.blank? || tenant.blank?
          cc.render status: 404, text: 'Not found'
          return
        end

        http = HTTP.timeout(connect: 30, read: 30).timeout(7200).follow(max_hops: 2)
          .basic_auth(user: tenant.repository.username, pass: tenant.repository.password)

        # ui: GET /api/presign-file/:object/:version/producer%2F:file
        r = http.get(file.merritt_presign_info_url)
        handle_bad_status(r, file)
        resp = r.parse.with_indifferent_access
        cc.redirect_to resp[:url]
      rescue HTTP::Error => e
        raise MerrittError, "HTTP Error while creating presigned URL with Merritt\n" \
          "#{file.merritt_presign_info_url}\n" \
          "Original HTTP library error: #{e}\n" \
          "#{e.backtrace.join("\n")}"
      end

      def handle_bad_status(r, file)
        return if r.status.success?

        raise MerrittError, "Merritt couldn't create presigned URL for #{url(file: file)}\nHttp status code: #{r.status.code}"
      end
    end
  end
end
