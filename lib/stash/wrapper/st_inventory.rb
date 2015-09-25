require 'xml/mapping'
require_relative 'st_stash_file'

module Stash
  module Wrapper

    # File inventory of the dataset submission package.
    class Inventory
      include ::XML::Mapping

      array_node :files, 'file', class: StashFile, default_value: []
      numeric_node :num_files, '@num_files', default_value: 0

      def initialize(files:)
        self.files = files
        self.num_files = files.size
      end
    end
  end
end
