require_relative '../harvester'

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
    end
  end
end
