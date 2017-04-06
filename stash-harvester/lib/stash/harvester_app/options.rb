require 'time'
require 'optparse'

module Stash
  module HarvesterApp
    class Options

      NOTE_DATETIME = ['DATETIME arguments:',
                       '  DATETIME arguments are inclusive and must be in ISO 8601 format',
                       '  (i.e. YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ). Note that if a time is',
                       '  specified, it must be in UTC.'].join("\n")

      NOTE_CONFIG = ['Configuration files:',
                     '  By default, stash-harvester looks for, in order:',
                     '    - a stash-harvester.yml file in the current working directory',
                     '    - a .stash-harvester file in the running user\'s home directory'].join("\n")

      NOTE_EXAMPLES = ['Examples:',
                       ['  Harvest all records in January 2015 from the data source given',
                        '  in the default configation file:',
                        "\n    $ stash-harvester -f 2015-01-01 -u 2015-01-31"].join("\n"),
                       ['  Harvest all records from 1 January 2015 to the present day',
                        '  from the data source given in the default configation file:',
                        "\n    $ stash-harvester -f 2015-01-01 -u 2015-01-31"].join("\n"),
                       ['  Harvest all records from the data source described in my-config.yml',
                        '  from the beginning of time to the present day:',
                        "\n    $ stash-harvester -c my-config.yml"].join("\n")].join("\n\n")

      NOTES = [NOTE_EXAMPLES, NOTE_CONFIG, NOTE_DATETIME].join("\n\n") + "\n"

      VERSION = "#{NAME} #{VERSION}\n#{COPYRIGHT}\n".freeze

      DATE_LENGTH = 'YYYY-MM-DD'.length

      def self.init_opts(options)
        OptionParser.new do |opts|
          opts.on('-h', '--help', 'display this help and exit') { options.show_help = true }
          opts.on('-v', '--version', 'output version information and exit') { options.show_version = true }
          opts.on('-f', '--from DATETIME', 'start date/time for selective harvesting') { |from_time| options.from_time = to_utc_time(from_time) }
          opts.on('-u', '--until DATETIME', 'end date/time for selective harvesting') { |until_time| options.until_time = to_utc_time(until_time) }
          opts.on('-c', '--config FILE', 'configuration file') { |config_file| options.config_file = config_file }
          opts.on('-s', '--stop-file FILE', 'stop file') { |stop_file| options.stop_file = stop_file }
        end
      end

      USAGE = "#{init_opts(nil)}\n".freeze

      HELP = "#{USAGE}#{NOTES}\n".freeze

      attr_accessor :show_version
      attr_accessor :show_help
      attr_accessor :from_time

      # @return [Time, nil] the
      attr_accessor :until_time

      # @return [String, nil] the path to the specified config file
      attr_accessor :config_file

      # @return [String, nil] the path to the specified stop file
      attr_accessor :stop_file

      def initialize(argv = nil)
        @opt_parser = self.class.init_opts(self)
        parse(argv)
      end

      def do_exit
        show_help || show_version || stop_file_present
      end

      def parse(argv)
        @opt_parser.parse(argv)
      end

      def stop_file_present
        stop_file && File.exist?(stop_file)
      end

      def stop_file_message
        return unless stop_file_present
        "Found stop file #{File.absolute_path(stop_file)}"
      end

      def self.to_time(time_str)
        if time_str
          if time_str.length > DATE_LENGTH
            Time.iso8601(time_str)
          else
            date = Date.iso8601(time_str)
            Time.utc(date.year, date.month, date.day)
          end
        end
      rescue ArgumentError
        raise(OptionParser::InvalidArgument, ": '#{time_str}' is not a valid ISO 8601 datetime")
      end
      private_class_method :to_time

      def self.to_utc_time(time_str)
        time = to_time(time_str)
        Util.utc_or_nil(time)
      end
      private_class_method :to_utc_time

    end
  end
end
