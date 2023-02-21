require 'uri'
require 'typesafe_enum'

module Stash
  module Deposit
    class Packaging < TypesafeEnum::Base

      new :BINARY, URI('http://purl.org/net/sword/package/Binary') do
        def content_type
          @content_type ||= 'application/octet-stream'
        end
      end

      new :SIMPLE_ZIP, URI('http://purl.org/net/sword/package/SimpleZip') do
        def content_type
          @content_type ||= 'application/zip'
        end
      end

      def header
        value.to_s
      end
    end
  end
end
