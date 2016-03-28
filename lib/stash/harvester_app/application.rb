require 'active_record'

# TODO: abstract out database stuff into its own interface
require 'db/models'

module Stash

  module HarvesterApp
    class Application

      attr_reader :config

      def initialize(config:)
        raise ArgumentError, "Invalid #{Application}.config; expected a #{Config}, got #{config ? config : 'nil'}" unless config && config.is_a?(Config)
        @config = config
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
        config = Config.from_file(config_file)
        with_config(config)
      end

      def start(from_time: nil, until_time: nil)
        from_time = Util.utc_or_nil(from_time)
        until_time = Util.utc_or_nil(until_time)

        job = HarvestAndIndexJob.new(
          source_config: source_config,
          index_config: index_config,
          metadata_mapper: metadata_mapper,
          from_time: from_time,
          until_time: until_time
        )

        job_record = Stash::Harvester::HarvestJob.new do |j|
          j.from_time = job.from_time
          j.until_time = job.until_time
          # j.query_url = job.query_url
          j.start_time = Time.now
          j.status = Stash::Harvester::Models::Status::IN_PROGRESS
        end
        job_record.save

        end_status = Stash::Harvester::Models::Status::COMPLETED
        begin
          job.harvest_and_index
        rescue
          end_status = Stash::Harvester::Models::Status::FAILED
        end

        job_record.end_time = Time.now
        job_record.status = end_status
      end

      def self.config_file_defaults
        [File.expand_path('stash-harvester.yml', Dir.pwd),
         File.expand_path('.stash-harvester.yml', Dir.home)]
      end

      private

      def init_connection
        @connection ||= ActiveRecord::Base.establish_connection(config.connection_info)
      end

      def index_config
        config.index_config
      end

      def source_config
        config.source_config
      end

      def metadata_mapper
        config.metadata_mapper
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

    end
  end
end
