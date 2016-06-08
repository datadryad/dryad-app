module Stash
  module Sword
    module LogUtils
      def log
        ::Stash::Sword.log
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
    end
  end
end
