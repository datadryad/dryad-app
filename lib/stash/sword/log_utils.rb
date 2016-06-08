module Stash
  module Sword
    module LogUtils
      def log
        ::Stash::Sword.log
      end

      def log_error(e)
        if e.respond_to?(:response)
          log.error(to_log_msg(e.response))
        else
          log.error('Unable to log response')
        end
      end

      def to_log_msg(response)
        [
          '-----------------------------------------------------',
          "code: #{response.code}",
          'headers:',
          response.headers.map { |k, v| "\t#{k}:#{v}" }.join("\n"),
          "body:\n#{response.body}",
          '-----------------------------------------------------'
        ].join("\n")
      end
    end
  end
end
