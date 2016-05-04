require 'sword2ruby'
require 'net/http/post/multipart'
require 'restclient'

module Stash
  module Sword
    class Client

      MULTIPART_RELATED_ATOM_XML = 'multipart/related; type="application/atom+xml"'.freeze

      attr_reader :username
      attr_reader :password
      attr_reader :on_behalf_of

      def initialize(username:, password:, on_behalf_of: nil)
        raise 'no username provided' unless username
        raise 'no password provided' unless password
        @username = username
        @password = password
        @on_behalf_of = on_behalf_of || username
      end

      def post_create(collection_uri:, zipfile:, slug:, &block)
        warn "#{zipfile} may not be a zipfile" unless zipfile.downcase.end_with?('.zip')
        collection_uri = URI(collection_uri.to_s) unless collection_uri.is_a?(URI)
        uri = collection_uri
        md5 = Digest::MD5.file(zipfile).to_s

        headers = {
          'Packaging' => 'http://purl.org/net/sword/package/SimpleZip',
          'On-Behalf-Of' => on_behalf_of,
          'Slug' => slug,
          'Content-MD5' => md5,
          'Content-Disposition' => "attachment; filename=#{File.basename(zipfile)}",
          'Content-Type' => 'application/zip'
        }

        request = RestClient::Request.new(
          method: :post,
          url: uri.to_s,
          user: username,
          password: password,
          headers: headers,
          payload: File.binread(zipfile)
        )
        request.execute(&block)
      end

      def post_update(se_iri:, slug:, new_zipfile:)
        send_update(Net::HTTP::Post, se_iri, slug, new_zipfile)
      end

      def put_update(edit_iri:, slug:, new_zipfile:)
        send_update(Net::HTTP::Put, edit_iri, slug, new_zipfile)
      end

      # TODO: Rewrite with RestClient
      def send_update(http_method, uri, slug, new_zipfile)
        uri = URI(uri.to_s) unless uri.is_a?(URI)
        warn "#{new_zipfile} may not be a zipfile" unless new_zipfile.downcase.end_with?('.zip')

        params = {
          'payload' => UploadIO.new(
            File.new(new_zipfile),
            'application/zip',
            'example.zip',
            'Content-Disposition' => 'attachment',
            'Packaging' => 'http://purl.org/net/sword/package/SimpleZip',
            'Content-MD5' => Digest::MD5.file(new_zipfile),
            'Mime-Version' => '1.0')
        }
        headers = {
          'Content-Type' => MULTIPART_RELATED_ATOM_XML,
          'On-Behalf-Of' => on_behalf_of,
          'Slug' => slug,
          'Mime-Version' => '1.0'
        }
        boundary = "========#{Time.now.to_i}=="

        req = http_method::Multipart.new(uri.path, params, headers, boundary)
        req.basic_auth(username, password)

        Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(req)
        end
      end

    end
  end
end
