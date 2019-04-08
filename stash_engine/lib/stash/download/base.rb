require 'logger'

module Stash
  module Download

    class MerrittResponseError < StandardError
    end

    # this is essentially an abstract class for version and file downloads to share common methods
    class Base
      attr_reader :cc

      def initialize(controller_context:)
        @cc = controller_context
      end

      # to stream the response through this UI instead of redirecting, keep login and other stuff private
      def stream_response(url:, tenant:)
        # get original header info from http headers
        client = Stash::Repo::HttpClient.new(tenant: tenant, cert_file: APP_CONFIG.ssl_cert_file).client

        headers = client.head(url, follow_redirect: true)

        content_type = headers.http_header['Content-Type'].try(:first)
        content_length = headers.http_header['Content-Length'].try(:first) || ''
        content_disposition = disposition_filename
        cc.response.headers['Content-Type'] = content_type if content_type
        cc.response.headers['Content-Disposition'] = content_disposition
        cc.response.headers['Content-Length'] = content_length
        cc.response.headers['Last-Modified'] = Time.now.httpdate
        cc.response_body = Stash::Streamer.new(client, url)
      end

      def self.log_warning_if_needed(error:, resource:)
        return unless Rails.env.development?
        msg = "MerrittResponseError checking sync/async download for resource #{resource.id} updated at #{resource.updated_at}"
        backtrace = error.respond_to?(:backtrace) && error.backtrace ? error.backtrace.join("\n") : ''
        Rails.logger.warn("#{msg}: #{error.class}: #{error}\n#{backtrace}")
      end
    end
  end
end
