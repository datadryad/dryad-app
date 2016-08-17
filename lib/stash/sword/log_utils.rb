module Stash
  module Sword
    module LogUtils

      def log
        @log ||= default_logger
      end

      def log_error(e)
        log.error(to_log_msg(e))
      end

      def to_log_msg(e)
        msg_lines = []

        if e.respond_to?(:message) && e.message
          msg_lines << "message: #{e.message}"
        else
          msg_lines << e.to_s
        end

        if e.respond_to?(:response) && e.response
          response = e.response
          msg_lines.unshift(*[
            "code: #{response.code}",
            'headers:', hash_to_log_msg(response.headers),
            "body:\n#{response.body}",
          ])
        end

        if e.respond_to?(:backtrace) && e.backtrace
          msg_lines.unshift(*e.backtrace)
        end

        msg_lines.join("\n")
      end

      def log_hash(hash)
        msg = hash_to_log_msg(hash)
        log.debug(msg)
      end

      def hash_to_log_msg(hash)
        hash.map do |k, v|
          value = v.is_a?(Hash) ? v.map { |k2, v2| "\n\t#{k2}: #{v2}" }.join : v
          "#{k}: #{value}"
        end.join("\n")
      end

      def level
        # TODO: make this configurable
        @level ||= case ENV['RAILS_ENV'].to_s.downcase
                   when 'test'
                     Logger::DEBUG
                   when 'development'
                     Logger::INFO
                   else
                     Logger::WARN
                   end
      end

      def default_logger
        LogUtils.create_default_logger($stdout, level)
      end

      def self.create_default_logger(io, level)
        logger = Logger.new(io, 10, 1024 * 1024)
        logger.level = level
        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.to_time.utc} #{severity} -#{progname}- #{msg}\n"
        end
        logger
      end

    end
  end
end
