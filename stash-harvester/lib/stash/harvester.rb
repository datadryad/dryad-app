require 'active_support'
require 'logger'
require 'stash'

module Stash
  # A gem for harvesting metadata from a digital repository for indexing
  module Harvester

    mattr_writer :log

    Dir.glob(File.expand_path('harvester/*.rb', __dir__)).sort.each(&method(:require))

    def self.log
      @log ||= new_logger(logdev: $stdout)
    end

    def self.log_device=(value)
      @log = new_logger(logdev: value)
    end

    def self.new_logger(logdev:, level: Stash::LOG_LEVEL, shift_age: 10, shift_size: 1024 * 1024)
      logger = Logger.new(logdev, shift_age, shift_size)
      logger.level = level
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.to_time.utc} #{severity} -#{progname}- #{msg}\n"
      end
      logger
    end

    private_class_method :new_logger
  end
end
