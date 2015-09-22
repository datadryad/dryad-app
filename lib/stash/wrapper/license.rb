require 'xml/mapping'
require 'xml/mapping_extensions'

module Stash
  module Wrapper
    # Dataset license.
    class License
      include ::XML::Mapping
      text_node :name, 'name'
      uri_node :uri, 'uri'
    end
  end
end
