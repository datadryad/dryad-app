require 'ruby-enum'

module Stash
  module Wrapper
    # Identifier type, drawn from the list defined by the DataCite schema.
    class IdentifierType
      include Ruby::Enum

      define :ARK, 'ARK'
      define :DOI, 'DOI'
      define :HANDLE, 'Handle'
      define :URL, 'URL'
    end
  end
end
