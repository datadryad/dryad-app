require 'digest'
require 'uri'
require 'stash/sword2/array_stream'
require 'stash/sword2/client/http_helper'

module Stash
  module Sword2
    module Client
      Dir.glob(File.expand_path('../client/*.rb', __FILE__)).sort.each(&method(:require))

      EOL                        = "\r\n".freeze
      SIMPLE_ZIP                 = 'http://purl.org/net/sword/package/SimpleZip'.freeze
      APPLICATION_ZIP            = 'application/zip'.freeze
      MULTIPART_RELATED_ATOM_XML = 'multipart/related; type="application/atom+xml"'.freeze

      attr_reader :username
      attr_reader :password
      attr_reader :on_behalf_of
      attr_reader :helper

      def initialize(username:, password:, on_behalf_of: nil, helper: nil)
        raise 'no username provided' unless username
        raise 'no password provided' unless password
        @username     = username
        @password     = password
        @on_behalf_of = on_behalf_of || username
        @helper       = helper || HTTPHelper.new(username: username, password: password, user_agent: "stash-sword2 #{VERSION}")
      end

      def self.new(*args)
        c = Class.new
        c.send(:include, self)
        c.new(*args)
      end

      def create(collection_uri:, slug:, zipfile:)
        warn "#{zipfile} may not be a zipfile" unless zipfile.downcase.end_with?('.zip')
        uri = Sword2.to_uri(collection_uri).to_s

        headers = create_request_headers(zipfile, slug)

        File.open(zipfile, 'rb') do |file|
          helper.post(uri: uri, payload: file, headers: headers)
        end
      end

      def update(edit_iri:, zipfile:)
        warn "#{zipfile} may not be a zipfile" unless zipfile.downcase.end_with?('.zip')
        uri = Sword2.to_uri(edit_iri).to_s

        boundary        = "========#{Time.now.to_i}=="
        stream          = stream_for(zipfile: File.open(zipfile, 'rb'), boundary: boundary)

        begin
          helper.put(uri: uri, headers: update_request_headers(stream, boundary), payload: stream)
        ensure
          stream.close
        end
      end

      private

      def create_request_headers(zipfile, slug)
        {
          'Content-Type'        => APPLICATION_ZIP,
          'Content-Disposition' => "attachment; filename=#{File.basename(zipfile)}",
          'Packaging'           => SIMPLE_ZIP,
          'Content-MD5'         => Digest::MD5.file(zipfile).to_s,
          'On-Behalf-Of'        => on_behalf_of,
          'Slug'                => slug
        }
      end

      def update_request_headers(stream, boundary)
        {
          'Content-Length' => stream.size.to_s,
          'Content-Type'   => "#{MULTIPART_RELATED_ATOM_XML}; boundary=\"#{boundary}\"",
          'On-Behalf-Of'   => on_behalf_of,
          'MIME-Version'   => '1.0'
        }
      end

      def update_mime_headers(zipfile)
        {
          'Content-Type'        => APPLICATION_ZIP,
          'Content-Disposition' => "attachment; name=payload; filename=\"#{File.basename(zipfile)}\"",
          'Packaging'           => SIMPLE_ZIP,
          'Content-MD5'         => Digest::MD5.file(zipfile).to_s,
          'MIME-Version'        => '1.0'
        }
      end

      def stream_for(zipfile:, boundary:)
        content = []
        # strictly speaking, do we need an Atom <entry/> first?
        content << "--#{boundary}#{EOL}"
        update_mime_headers(zipfile).each { |k, v| content << "#{k}: #{v}#{EOL}" }
        content << zipfile
        content << "--#{boundary}--#{EOL}"
        ArrayStream.new(content)
      end

    end
  end
end
