require 'ruby-enum'

module Stash
  module Wrapper
    # Controlled vocabulary for {Identifier#type}
    class IdentifierType
      include Ruby::Enum

      define :ARK, 'ARK'
      define :DOI, 'DOI'
      define :HANDLE, 'Handle'
      define :URL, 'URL'
    end
  end
end
