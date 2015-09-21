require 'xml/mapping'
require 'xml/mapping_extensions'

module Stash
  module Wrapper
    # Dataset version
    class Version
      include ::XML::Mapping
      numeric_node :version_number, 'version_number'
      date_node :date, 'date'
      text_node :note, 'note', default_value: nil
    end
  end
end
