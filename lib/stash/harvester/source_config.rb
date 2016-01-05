require 'config/factory'

module Stash
  module Harvester

    # Superclass for configuration of any data source.
    #
    # @!attribute [r] source_uri
    #   @return [URI] the base URL of the repository.
    class SourceConfig
      include ::Config::Factory

      key :protocol

      attr_reader :source_uri

      # Constructs a new +SourceConfig+ with the specified properties.
      #
      # @param source_url [URI, String] the base URL of the repository. *(Required)*
      # @raise [URI::InvalidURIError] if +source_url+ is a string that is not a valid URI
      def initialize(source_url:)
        @source_uri = Util.to_uri(source_url)
      end

      # Constructs a new +HarvestTask+ from this configuration. Implementors should
      # override this method to return an appropriate subclass of +HarvestTask+ for
      # the data source.
      #
      # @return [HarvestTask] a task to harvest records for the specified time range
      def create_harvest_task(_from_time: nil, _until_time: nil)
        fail NoMethodError, "#{self.class} should override #create_harvest_task to create a HarvestTask, but it doesn't"
      end
    end
  end
end
