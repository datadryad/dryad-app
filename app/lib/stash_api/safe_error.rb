# frozen_string_literal: true

module StashApi
  class SafeError < StandardError
    attr_reader :original_exception,
                :metadata

    def initialize(message = nil, original: nil, metadata: {})
      super(message)

      @message = message # needed so we can set defaults for it
      @original_exception = original
      @metadata = metadata
    end

    # this should be overridden by inheriting exception classes
    def http_status
      500
    end
  end
end
