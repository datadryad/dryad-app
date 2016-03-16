require 'config/factory'
require 'stash/indexer/index_config'

module Stash
  module Harvester
    class Config

      # The database connection info, as a hash
      # @return [Hash<String, String>] the database connection info
      attr_reader :connection_info

      # The harvest source configuration
      # @return [SourceConfig] the configuration (as an appropriate
      #   subclass of `SourceConfig` for the specified protocol)
      attr_reader :source_config

      # The index configuration
      # @return [IndexConfig] the configuration (as an apporpriate
      #   subclass of `IndexConfig` for the specified adapter)
      attr_reader :index_config

      # The metadata mapper
      # @return [MetadataMapper] the mapper (as an appropriate
      #   subclass of `MetadataMapper` for the specified mapping)
      attr_reader :metadata_mapper

      def initialize(connection_info:, source_config:, index_config:, metadata_mapper:)
        @connection_info = connection_info
        @source_config = source_config
        @index_config = index_config
        @metadata_mapper = metadata_mapper
      end

      # Reads the specified file and creates a new `Config` from it.
      #
      # @param path [String] the path to read the YAML from
      # @raise [IOError] in the event the file does not exist, cannot be read, or is invalid
      def self.from_file(path)
        validate_path(path)
        begin
          env = ::Config::Factory::Environment.load_file(path)
          from_env(env)
        rescue IOError
          raise
        rescue => e
          raise IOError, "Error parsing specified config file #{path}: #{e.message}"
        end
      end

      # Creates a new `Config` for the specified environment.
      #
      # @param env [Config::Factory::Environment] the configuration environment.
      def self.from_env(env)
        connection_info = env.args_for(:db)
        source_config = SourceConfig.for_environment(env, :source)
        index_config = Stash::Indexer::IndexConfig.for_environment(env, :index)
        metadata_mapper = Stash::Indexer::MetadataMapper.for_environment(env, :mapper)
        Config.new(connection_info: connection_info, source_config: source_config, index_config: index_config, metadata_mapper: metadata_mapper)
      end

      # Private methods

      def self.validate_path(path)
        raise IOError, "Specified config file #{path} does not exist" unless File.exist?(path)
        raise IOError, "Specified config file #{path} is not a file" unless File.file?(path)
        raise IOError, "Specified config file #{path} is not readable" unless File.readable?(path)
      end

      private_class_method :validate_path
    end
  end
end
