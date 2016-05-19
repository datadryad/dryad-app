module Stash
  module Sword2
    module HeaderUtils

      SIMPLE_ZIP                 = 'http://purl.org/net/sword/package/SimpleZip'.freeze
      APPLICATION_ZIP            = 'application/zip'.freeze
      MULTIPART_RELATED_ATOM_XML = 'multipart/related; type="application/atom+xml"'.freeze

      attr_reader :on_behalf_of

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
    end
  end
end
