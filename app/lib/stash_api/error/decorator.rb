# frozen_string_literal: true

module StashApi
  module Error
    class Decorator
      attr_reader :code, :message, :metadata

      def initialize(code:, message:, field: nil, metadata: {})
        @code = code
        @message = message
        @field = field if field
        @metadata = metadata
      end
    end
  end
end
