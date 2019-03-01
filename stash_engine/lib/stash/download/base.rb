# Dir.glob(File.expand_path('download/*.rb', __dir__)).sort.each(&method(:require))
module Stash
  module Download
    class Base
      attr_reader :cc

      def initialize(controller_context:)
        @cc = controller_context
      end

      # to stream the response through this UI instead of redirecting, keep login and other stuff private
      # rubocop:disable Metrics/AbcSize
      def stream_response(url:, tenant:)
        # get original header info from http headers
        client = Stash::Repo::HttpClient.new(tenant: tenant, cert_file: APP_CONFIG.ssl_cert_file).client

        headers = client.head(url, follow_redirect: true)

        content_type = headers.http_header['Content-Type'].try(:first)
        content_length = headers.http_header['Content-Length'].try(:first) || ''
        content_disposition = headers.http_header['Content-Disposition'].try(:first) || disposition_from(url)
        cc.response.headers['Content-Type'] = content_type if content_type
        cc.response.headers['Content-Disposition'] = content_disposition
        cc.response.headers['Content-Length'] = content_length
        cc.response.headers['Last-Modified'] = Time.now.httpdate
        cc.response_body = Stash::Streamer.new(client, url)
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end