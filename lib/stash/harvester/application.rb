module Stash
  module Harvester
    class Application

      def initialize(from_time: nil, until_time: nil, config_file: nil)
        puts "from_time:\t#{from_time}"
        puts "until_time:\t#{until_time}"
        puts "config_file:\t#{config_file}"
      end

      def start
      end

      private

      def ensure_config_file(config_file)
        config_file ||= default_config_file
        fail ArgumentError, "No configuration file provided, and none found in default locations #{config_file_defaults.join(' or ')}" unless config_file
        config_file
      end

      def default_config_file
        config_file_defaults.each do |cf|
          return cf if File.exist?(cf)
        end
      end

      def config_file_defaults
        [File.expand_path('stash-harvester.yml', Dir.pwd),
         File.expand_path('.stash-harvester.yml', Dir.home)]
      end

    end
  end
end
