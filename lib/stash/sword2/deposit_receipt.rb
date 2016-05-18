require 'xml/mapping_extensions'

module Stash
  module Sword2
    class DepositReceipt
      include XML::MappingExtensions::Namespaced

      root_element_name 'entry'
      namespace Namespace::ATOM.value
    end
  end
end
