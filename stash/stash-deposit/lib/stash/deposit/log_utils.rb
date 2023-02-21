module Stash
  module Deposit
    module LogUtils

      def logger
        @logger ||= default_logger
      end

      def log_error(e)
        logger.error(to_log_msg(e))
      end

      def to_log_msg(e)
        msg_lines = []
        append_message(msg_lines, e)
        append_response(msg_lines, e)
        append_backtrace(msg_lines, e)
        msg_lines.join("\n")
      end

      def log_hash(hash)
        msg = hash_to_log_msg(hash)
        logger.debug(msg)
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

      private

      def append_message(msg_lines, e)
        msg_lines << if e.respond_to?(:message) && e.message
                       "message: #{e.message}"
                     else
                       e.to_s
                     end
      end

      def append_response(msg_lines, e)
        return unless e.respond_to?(:response) && e.response

        response = e.response
        msg_lines.unshift(
          "code: #{response.code}",
          'headers:', hash_to_log_msg(response.headers),
          "body:\n#{response.body}"
        )
      end

      def append_backtrace(msg_lines, e)
        return unless e.respond_to?(:backtrace) && e.backtrace

        msg_lines.unshift(*e.backtrace)
      end

    end
  end
end
