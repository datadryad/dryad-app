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
        self.files = valid_file_array(files)
        self.num_files = files.size
      end

      private

      def valid_file_array(files)
        raise ArgumentError, "specified file list does not appear to be an array of StashFiles: #{files.inspect}" unless files.is_a?(Array)

        files.each_with_index do |f, i|
          raise ArgumentError, "files[#{i}] does not appear to be a StashFile: #{f.inspect}" unless f.is_a?(StashFile)
        end
        files
      end
    end
  end
end
