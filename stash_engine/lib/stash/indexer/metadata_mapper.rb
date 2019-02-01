module Stash
  module Indexer

    # Superclass of installation-specific mappers converting wrapped metadata to
    # indexable documents.
    class MetadataMapper

      key :metadata_mapping

      attr_reader :opts

      def initialize(*opts)
        @opts = opts
      end

      # Converts a Stash-wrapped metadata document to an indexable document.
      #
      # @param wrapped_metadata [StashWrapper] a Stash-wrapped metadata document with
      #   appropriate descriptive elements for this mapper.
      # @return [Object] a document extracting information from `wrapped_metadata`
      #   and formatting it appropriately for the index supported by this mapper.
      def to_index_document(wrapped_metadata) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, "#{self.class} should override #to_index_document to map wrapped metadata to indexable documents, but it doesn't"
      end

      # Describes what (wrapped) metadata format or formats this mapper supports
      # @return [String] a human-readable description of the metadata format or formats
      #   consumed by this mapper
      def desc_from
        raise NoMethodError, "#{self.class} should override #desc_from to describe what it maps from, but it doesn't"
      end

      # Describes what index protocol or format and schema this mapper supports
      # @return [String] a human-readable description of the type of index document
      #   produced by this mapper
      def desc_to
        raise NoMethodError, "#{self.class} should override #desc_to to describe what it maps to, but it doesn't"
      end

      def description
        "#{self.class} (#{desc_from} -> #{desc_to})"
      end
    end
  end
end
