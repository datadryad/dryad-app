module Stash
  module Sword
    module LogUtils

      def log
        @log ||= default_logger
      end

      def log_error(e)
        if e.respond_to?(:response)
          log.error(response_to_log_msg(e.response))
        else
          log.error('Unable to log response')
        end
      end

      def response_to_log_msg(response)
        [
          '-----------------------------------------------------',
          "code: #{response.code}",
          'headers:', hash_to_log_msg(response.headers),
          "body:\n#{response.body}",
          '-----------------------------------------------------'
        ].join("\n")
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
        logger = Logger.new($stdout, 10, 1024 * 1024)
        logger.level = level
        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.to_time.utc} #{severity} -#{progname}- #{msg}\n"
        end
        logger
      end

    end
  end
end
