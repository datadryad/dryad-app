require 'xml/mapping'
require_relative 'date_node'

module Stash
  module Wrapper
    # Dataset version
    class Version
      include ::XML::Mapping
      numeric_node :version_number, 'version_number'
      date_node :date, 'date'
      text_node :note, 'note'
    end
  end
end
