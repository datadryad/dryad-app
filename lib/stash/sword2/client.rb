module Stash
  module Sword2
    module Client
      Dir.glob(File.expand_path('../client/*.rb', __FILE__)).sort.each(&method(:require))

      attr_reader :username
      attr_reader :password
      attr_reader :on_behalf_of
      attr_reader :helper

      def initialize(username:, password:, on_behalf_of: nil, helper: nil)
        raise 'no username provided' unless username
        raise 'no password provided' unless password
        @username = username
        @password = password
        @on_behalf_of = on_behalf_of || username
        @helper = helper || HTTPHelper.new(username: username, password: password, user_agent: "stash-sword2 #{VERSION}")
      end

      def self.new(*args)
        c = Class.new
        c.send(:include, self)
        c.new(*args)
      end

      def create(collection_uri:, slug:, zipfile:)
        warn "#{zipfile} may not be a zipfile" unless zipfile.downcase.end_with?('.zip')
        uri = Sword2.to_uri(collection_uri).to_s
        md5 = Digest::MD5.file(zipfile).to_s

        File.open(zipfile, 'rb') do |file|
          helper.post(uri: uri, payload: file, headers: {
                        'Packaging' => 'http://purl.org/net/sword/package/SimpleZip',
                        'On-Behalf-Of' => on_behalf_of,
                        'Slug' => slug,
                        'Content-MD5' => md5,
                        'Content-Disposition' => "attachment; filename=#{File.basename(zipfile)}",
                        'Content-Type' => 'application/zip'
                      })
        end
      end

      def update(edit_iri:, slug:, zipfile:)
        warn "#{zipfile} may not be a zipfile" unless zipfile.downcase.end_with?('.zip')
        uri = Sword2.to_uri(edit_iri).to_s
        md5 = Digest::MD5.file(zipfile).to_s

        boundary = "========#{Time.now.to_i}=="

        stream = stream_from(md5: md5, zipfile: File.open(zipfile, 'rb'), boundary: boundary)

        begin
          request_headers = {
              'Content-Length' => stream.size.to_s,
              'Content-Type' => "multipart/related; type=\"application/atom+xml\"; boundary=\"#{boundary}\"",
              'On-Behalf-Of' => on_behalf_of,
              'Slug' => slug
          }
          helper.put(uri: uri, headers: request_headers, payload: stream)
        ensure
          stream.close
        end
      end

      def stream_from(md5:, zipfile:, boundary:)
        separator = "--#{boundary}"
        content = []
        # TODO: don't forget to join everything with EOLs
        ArrayStream.new(content)
      end

    end
  end
end

module RestClient
  # Patch to support (SWORD 2 subset of) multipart/related in RestClient

  module Payload
    class MultipartRelated < Base
      EOL = "\r\n".freeze

      def build_stream(_params)
        separator = "--#{boundary}"
        read, write = IO.pipe(binmode: true)
        begin
          write.binmode
          # TODO: do we need to write anything here?
          write.write("#{separator}#{EOL}")
          # TODO: write MIME headers for metadata
          # TODO: write <entry/>
          write.write("#{separator}#{EOL}")
        # TODO: write MIME headers for data
        # TODO: stream zipfile data
        rescue
          write.write("#{separator}--#{EOL}")
          write.close
        end
        # TODO: this is obviously wrong, it's going to deadlock
        read
      end

      def boundary
        @boundary ||= "========#{Time.now.to_i}=="
      end
    end
  end
end
