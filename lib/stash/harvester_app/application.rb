module Stash
  module HarvesterApp
    class Application

      attr_reader :config

      def initialize(config:)
        raise ArgumentError, "Invalid #{Application}.config; expected a #{Config}, got #{config ? config : 'nil'}" unless config && config.is_a?(Config)
        @config = config

        [:persistence_config, :source_config, :index_config, :metadata_mapper].each do |c|
          sub_config = config.send(c)
          log.debug("#{c}: #{sub_config ? sub_config.description : 'nil'}")
        end
      end

      private_class_method :new

      # Initializes a new `Application` with the specified configuration
      # @param config [Config] The configuration object
      def self.with_config(config)
        new(config: config)
      end

      # Initializes a new `Application` with the specified configuration file. If
      # no configuration file is provided, by default, `Application` will look for:
      #
      # 1. `stash-harvester.yml` in the current working directory
      # 2. `.stash-harvester.yml` in the user's home directory
      #
      # @param config_file [String] The configuration file, or nil to search for a
      #   default configuration file
      def self.with_config_file(config_file = nil)
        config_file = ensure_config_file(config_file)
        log.debug("Initializing #{self} with #{config_file}")
        config = Config.from_file(config_file)
        with_config(config)
      end

      def start(from_time: nil, until_time: nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        from_time = Util.utc_or_nil(from_time)
        until_time = Util.utc_or_nil(until_time)

        job = create_job(from_time, until_time)
        job.harvest_and_index do |result|
          record = result.record
          record_identifier = record ? record.identifier : 'nil'
          log.debug("Indexed record #{record_identifier}: #{result.status}")

          # TODO: log these in a sort-friendly way
          result.errors.each do |e|
            log.error(e.message)
            log.debug(e.backtrace.join("\n")) if e.backtrace
          end
        end
      end

      def self.config_file_defaults
        [File.expand_path('stash-harvester.yml', Dir.pwd),
         File.expand_path('.stash-harvester.yml', Dir.home)]
      end

      def self.log
        ::Stash::Harvester.log
      end

      def log
        ::Stash::Harvester.log
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

      def persistence_manager
        @persistence_mgr ||= config.persistence_config.create_manager
      end

      def self.ensure_config_file(config_file)
        config_file ||= default_config_file
        raise ArgumentError, "No configuration file provided, and none found in default locations #{Application.config_file_defaults.join(' or ')}" unless config_file
        config_file
      end

      private_class_method :ensure_config_file

      def self.default_config_file
        Application.config_file_defaults.each do |cf|
          return cf if File.exist?(cf)
        end
        nil
      end

      private_class_method :default_config_file

      def create_job(from_time = nil, until_time = nil)
        HarvestAndIndexJob.new(
          source_config: source_config,
          index_config: index_config,
          metadata_mapper: metadata_mapper,
          persistence_manager: persistence_manager,
          from_time: determine_from_time(from_time),
          until_time: until_time
        )
      end

      def determine_from_time(from_time) # rubocop:disable Metrics/AbcSize
        if from_time
          log.debug("Starting harvest from provided timestamp #{from_time.utc.xmlschema}")
        elsif (from_time = persistence_manager.find_oldest_failed_timestamp)
          log.debug("Starting harvest from timestamp (inclusive) of last failed record: #{from_time.utc.xmlschema}")
        elsif (from_time = persistence_manager.find_newest_indexed_timestamp)
          log.debug("Starting harvest from timestamp (inclusive) of last successfully indexed record: #{from_time.utc.xmlschema}")
        else
          log.debug('No start timestamp provided, and no previous harvest found; harvesting all records')
        end
        from_time
      end
    end
  end
end
