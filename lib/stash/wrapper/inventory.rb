require 'xml/mapping'
require 'stash/wrapper/stash_file'

module Stash
  module Wrapper

    # Mapping class for `<st:inventory>`
    class Inventory
      include ::XML::Mapping

      array_node :files, 'file', class: StashFile, default_value: []
      numeric_node :num_files, '@num_files', default_value: 0

      # creates a new {Inventory} object
      # @param files [List<StashFile>] The inventory of files
      def initialize(files:)
        self.files = files
        self.num_files = files.size
      end
    end
  end
end
