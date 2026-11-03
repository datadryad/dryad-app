module Middleware
  class AuthFailureLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      status, headers, body = @app.call(env)

      if request.path == '/oauth/token' && status == 401
        AuthFailureService.new(
          request,
          nil,
          get_params(request)
        ).create(:api_unauthorized)
      end

      [status, headers, body]
    rescue IPAddr::InvalidAddressError => e
      # Gracefully handle the invalid IP header injection
      # returning a 400 Bad Request directly to the scanner
      Rails.logger.warn("AuthFailureLogger intercepted invalid IP address: #{e.message}")
      [400, { 'Content-Type' => 'text/plain' }, ['Bad Request: Invalid IP Address']]
    rescue StandardError => e
      Rails.logger.error("AuthFailureLogger error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      raise
    end

    def get_params(request)
      request.params.except('password')
    end
  end
end
