module Stash

  module HarvesterApp
    class Application

      attr_reader :from_time
      attr_reader :until_time
      attr_reader :config

      def initialize(from_time: nil, until_time: nil, config_file: nil)
        @from_time = Util.utc_or_nil(from_time)
        @until_time = Util.utc_or_nil(until_time)
        self.config = config_file
      end

      def start # rubocop:disable Metrics/AbcSize
        STDERR.puts "from_time: #{from_time}"
        STDERR.puts "until_time: #{until_time}"
        STDERR.puts "connection_info: #{config.connection_info}"
        STDERR.puts "source_uri: #{config.source_config.source_uri}"
        STDERR.puts "index_uri: #{config.index_config.uri}"
        STDERR.puts "metadata_mapper: #{config.metadata_mapper.desc_from} -> #{config.metadata_mapper.desc_to}"
        # job = HarvestAndIndexJob.new(
        #   source_config: source_config,
        #   index_config: index_config,
        #   metadata_mapper: metadata_mapper,
        #   from_time: from_time,
        #   until_time: until_time
        # )
        # job.harvest_and_index
      end

      def self.config_file_defaults
        [File.expand_path('stash-harvester.yml', Dir.pwd),
         File.expand_path('.stash-harvester.yml', Dir.home)]
      end

      private

      def index_config
        config.index_config
      end

      def source_config
        config.source_config
      end

      def metadata_mapper
        config.metadata_mapper
      end

      def config=(value)
        config_file = ensure_config_file(value)
        @config = Config.from_file(config_file)
      end

      def ensure_config_file(config_file)
        config_file ||= default_config_file
        raise ArgumentError, "No configuration file provided, and none found in default locations #{Application.config_file_defaults.join(' or ')}" unless config_file
        config_file
      end

      def default_config_file
        Application.config_file_defaults.each do |cf|
          return cf if File.exist?(cf)
        end
        nil
      end

    end
  end
end
