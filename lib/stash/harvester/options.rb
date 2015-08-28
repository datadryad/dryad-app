require 'time'
require 'optparse'

module Stash
  module Harvester
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
                        '    $ stash-harvester -f 2015-01-01 -u 2015-01-31'
                       ].join("\n"),
                       ['  Harvest all records from 1 January 2015 to the present day',
                        '  from the data source given in the default configation file:',
                        '    $ stash-harvester -f 2015-01-01 -u 2015-01-31'
                       ].join("\n"),
                       ['  Harvest all records from the data source described in my-ds.yml',
                        '  from the beginning of time to the present day:',
                        '    $ stash-harvester -c my-ds.yml'
                       ].join("\n")
      ].join("\n\n")

      NOTES = [NOTE_DATETIME, NOTE_CONFIG, NOTE_EXAMPLES].join("\n\n")

      attr_reader :show_version
      attr_reader :show_help
      attr_reader :from_time
      attr_reader :until_time
      attr_reader :config_file

      def initialize(argv = nil)
        parse(argv)
      end

      private

      def parse(argv)
        opt_parser = OptionParser.new do |opts|
          opts.on('-h', '--help', 'display this help and exit') do
            @show_help = true
            return
          end
          opts.on('-v', '--version', 'output version information and exit') do
            @version = true
            return
          end
          opts.on('-f', '--from DATETIME', 'start date/time for selective harvesting') do |from_time|
            @from_time = time_or_nil(from_time)
          end
          opts.on('-u', '--until DATETIME', 'end date/time for selective harvesting') do |until_time|
            @until_time = time_or_nil(until_time)
          end
          opts.on('-c', '--config FILE', 'configuration file') do |config_file|
            @config_file = config_file
          end
        end
        opt_parser.parse(argv)
      end

      def time_or_nil(time_str)
        time_str && Time.iso8601(time_str)
      end

    end
  end
end
