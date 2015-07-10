require 'oai/client'
require 'time'
require_relative '../harvested_record'

module Stash
  module Harvester
    module OAIPMH

      # A utility wrapper around +OAI::Record+ that flattens the OAI XML structure
      # and converts types (e.g., string datestamps to +Time+ objects)
      #
      # @!attribute [r] timestamp
      #   @return [Time] The datestamp of the record.
      # @!attribute [r] deleted
      #   @return [Boolean] True if the record is deleted, false otherwise.
      # @!attribute [r] identifier
      #   @return [String] The OAI identifier of the record.
      # @!attribute [r] metadata_root
      #   @return [REXML::Element] The root (inner) element of the record metadata.
      class Record < Stash::Harvester::HarvestedRecord

        attr_reader :metadata_root

        # @param record [OAI::Record] An OAI record as returned by +OAI::Client+
        def initialize(record)
          super(
            identifier: record.header.identifier,
            timestamp: Time.parse(record.header.datestamp),
            deleted: record.deleted?
          )
          @metadata_root = record.deleted? ? nil : record.metadata.elements[1]
        end

        def content
          @content ||= begin
            formatter = REXML::Formatters::Pretty.new
            formatter.compact = true
            out = StringIO.new
            formatter.write(metadata_root, out)
            out.string
          end
        end

        # TODO: document this
        def ==(other) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
          return true if self.equal?(other)
          return false unless other.instance_of?(self.class)
          return false unless other.timestamp == timestamp
          return false unless other.deleted? == deleted?
          return false unless other.identifier == identifier
          return false unless other.metadata_root.to_s == metadata_root.to_s
          true
        end
      end

    end
  end
end
