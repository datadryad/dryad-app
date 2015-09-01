require 'active_support'
require 'logger'

module Stash
  # A gem for harvesting metadata from a digital repository for indexing
  module Harvester

    mattr_writer :log

    Dir.glob(File.expand_path('../harvester/*.rb', __FILE__), &method(:require))

    def self.log
      @log ||= new_logger(logdev: STDOUT)
    end

    private

    def self.new_logger(logdev:, level: Logger::DEBUG, shift_age: 10, shift_size: 1024 * 1024)
      logger = Logger.new(logdev, shift_age, shift_size)
      logger.level = level
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.to_time.utc} #{severity} -#{progname}- #{msg}"
      end
      logger
    end

  end
end
