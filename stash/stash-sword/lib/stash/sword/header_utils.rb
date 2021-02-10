module Stash
  module Sword
    module HeaderUtils

      MULTIPART_RELATED_ATOM_XML = 'multipart/related; type="application/atom+xml"'.freeze
      CONTENT_DISPOSITION        = 'attachment'.freeze
      # CONTENT_DISPOSITION        = 'form-data'.freeze

      attr_reader :on_behalf_of

      def create_request_headers(payload, slug, packaging)
        {
          'Content-Type' => packaging.content_type,
          'Content-Disposition' => "#{CONTENT_DISPOSITION}; filename=#{File.basename(payload)}",
          'Packaging' => packaging.header,
          'Content-MD5' => Digest::MD5.file(payload).to_s,
          'On-Behalf-Of' => on_behalf_of,
          'Slug' => slug
        }
      end

      def update_request_headers(stream, boundary)
        {
          'Content-Length' => stream.size.to_s,
          'Content-Type' => "#{MULTIPART_RELATED_ATOM_XML}; boundary=\"#{boundary}\"",
          'On-Behalf-Of' => on_behalf_of,
          'MIME-Version' => '1.0'
        }
      end

      def update_mime_headers(payload, packaging)
        {
          'Content-Type' => packaging.content_type,
          'Content-Disposition' => "#{CONTENT_DISPOSITION}; name=\"payload\"; filename=\"#{File.basename(payload)}\"",
          'Packaging' => packaging.header,
          'Content-MD5' => Digest::MD5.file(payload).to_s,
          'MIME-Version' => '1.0'
        }
      end
    end
  end
end
