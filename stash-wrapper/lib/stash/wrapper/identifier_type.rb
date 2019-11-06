require 'typesafe_enum'

module Stash
  module Wrapper
    # Controlled vocabulary for {Identifier#type}
    class IdentifierType < TypesafeEnum::Base
      new :ARK, 'ARK'
      new :DOI, 'DOI'
      new :HANDLE, 'Handle'
      new :URL, 'URL'

      def format(id_value)
        return id_value if self == URL || self == HANDLE # TODO: is this close enough?
        "#{value.downcase}:#{id_value}"
      end
    end
  end
end
