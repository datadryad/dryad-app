module Stash
  module Harvester
    class Application

      attr_reader :from_time
      attr_reader :until_time
      attr_reader :config

      def initialize(from_time: nil, until_time: nil, config_file: nil)
        @from_time = Util.utc_or_nil(from_time)
        @until_time = Util.utc_or_nil(until_time)
        @config = ensure_config(config_file)
      end

      def start
      end

      private

      def ensure_config(config_file)
        config_file = Application.ensure_config_file(config_file)
        Config.from_file(config_file)
      end

      # TODO: Refactor tests to make these private

      def self.ensure_config_file(config_file)
        config_file ||= default_config_file
        fail ArgumentError, "No configuration file provided, and none found in default locations #{config_file_defaults.join(' or ')}" unless config_file
        config_file
      end

      def self.default_config_file
        config_file_defaults.each do |cf|
          return cf if File.exist?(cf)
        end
        nil
      end

      def self.config_file_defaults
        [File.expand_path('stash-harvester.yml', Dir.pwd),
         File.expand_path('.stash-harvester.yml', Dir.home)]
      end

    end
  end
end
