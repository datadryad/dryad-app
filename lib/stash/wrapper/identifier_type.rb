require 'typesafe_enum'

module Stash
  module Wrapper
    # Controlled vocabulary for {Identifier#type}
    class IdentifierType < TypesafeEnum::Base
      new :ARK, 'ARK'
      new :DOI, 'DOI'
      new :HANDLE, 'Handle'
      new :URL, 'URL'
    end
  end
end
