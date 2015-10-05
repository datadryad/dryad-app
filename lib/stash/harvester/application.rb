require_relative 'config'
require_relative 'util'

module Stash
  module Harvester
    class Application

      attr_reader :from_time
      attr_reader :until_time
      attr_reader :config

      def initialize(from_time: nil, until_time: nil, config_file: nil)
        @from_time = Util.utc_or_nil(from_time)
        @until_time = Util.utc_or_nil(until_time)
        self.config = config_file
      end

      def start
        # puts "from_time: #{from_time}"
        # puts "until_time: #{until_time}"
        # puts "connection_info: #{config.connection_info}"
        # puts "source_uri: #{config.source_config.source_uri}"
        # puts "index_uri: #{config.index_config.uri}"
      end

      def self.config_file_defaults
        [File.expand_path('stash-harvester.yml', Dir.pwd),
         File.expand_path('.stash-harvester.yml', Dir.home)]
      end

      private

      def config=(value)
        config_file = ensure_config_file(value)
        @config = Config.from_file(config_file)
      end

      def ensure_config_file(config_file)
        config_file ||= default_config_file
        fail ArgumentError, "No configuration file provided, and none found in default locations #{Application.config_file_defaults.join(' or ')}" unless config_file
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
