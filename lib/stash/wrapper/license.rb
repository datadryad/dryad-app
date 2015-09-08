require 'xml/mapping'
require_relative 'uri_node'

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
