require 'uri'
require 'typesafe_enum'

module Stash
  module Sword
    class IRI < TypesafeEnum::Base

      new :BINARY, URI('http://purl.org/net/sword/package/Binary')
      new :SIMPLE_ZIP, URI('http://purl.org/net/sword/package/SimpleZip')
    end
  end
end
