# frozen_string_literal: true

module StashApi
  module Error
    RESCUABLE_EXCEPTIONS = %w[
      StashApi::SafeError
      ActiveRecord::RecordInvalid
      ActiveRecord::RecordNotFound
      Exception
    ].freeze

    class BadRequestError < StashApi::SafeError
      def http_status
        400
      end
    end

    class UnauthorizedError < StashApi::SafeError
      def message
        @message || 'Not Authorized'
      end

      def http_status
        401
      end
    end

    class NotFoundError < StashApi::SafeError
      def message
        @message || 'Not Found'
      end

      def http_status
        404
      end
    end

    class ForbiddenError < StashApi::SafeError
      def http_status
        403
      end
    end

    class ExpectationError < StashApi::SafeError
      def http_status
        417 # expectation failed status code
      end
    end

    class ExpirationError < StashApi::SafeError
      def http_status
        419 # unofficial timeout status code
      end
    end

    class FailedDependencyError < StashApi::SafeError
      def http_status
        424 # failed dependency
      end
    end

    class UnprocessableEntityError < StashApi::SafeError
      def http_status
        422
      end
    end

    class ServerError < StashApi::SafeError
      def message
        if Rails.env.test? || Rails.env.development?
          @message
        else
          'We have encountered an error processing the request. Please try again, and if the problem persists, contact support.'
        end
      end

      def http_status
        500
      end
    end
  end
end
