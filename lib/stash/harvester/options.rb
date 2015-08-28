require 'time'
require 'trollop'

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

      PARSER = Trollop::Parser.new do
        opt :version, 'print the version'
        opt :from, 'start date/time for selective harvesting', type: :string
        opt :until, 'end date/time for selective harvesting', type: :string
        opt :config, 'configuration file', type: :string
        opt :help, 'show this message'
      end

      attr_reader :show_version
      attr_reader :show_help
      attr_reader :from_time
      attr_reader :until_time
      attr_reader :config_file

      def initialize(argv)
        opts = PARSER.parse(argv)
        @show_version = opts[:version]
        @show_help = opts[:help]
        @from_time = (from_time = opts[:from]) ? Time.iso8601(from_time) : nil
        @until_time = (until_time = opts[:until]) ? Time.iso8601(until_time) : nil
        @config = opts[:config]
      end
    end
  end
end
