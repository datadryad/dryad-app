require 'ipaddr'

module Middleware
  class AuthFailureLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      # Validate the IP address
      ip_address = extract_ip_address(request)
      begin
        # Check if the IP address is present and valid
        raise IPAddr::InvalidAddressError, 'IP address is missing' if ip_address.blank?

        IPAddr.new(ip_address)
      rescue IPAddr::InvalidAddressError => e
        # Gracefully handle the invalid IP header injection
        # returning a 400 Bad Request directly to the scanner
        Rails.logger.warn("AuthFailureLogger intercepted invalid IP address: #{e.message}")
        return [400, { 'Content-Type' => 'text/plain' }, ['Bad Request: Invalid IP Address']]
      end

      status, headers, body = @app.call(env)

      if request.path == '/oauth/token' && status == 401
        AuthFailureService.new(
          request,
          nil,
          get_params(request)
        ).create(:api_unauthorized)
      end

      [status, headers, body]
    rescue StandardError => e
      Rails.logger.error("AuthFailureLogger error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      raise
    end

    def get_params(request)
      request.params.except('password')
    end

    private

    def extract_ip_address(request)
      # Check if X-Forwarded-For header is present
      if request.headers['X-Forwarded-For'].present?
        # Get the first IP address from X-Forwarded-For
        request.headers['X-Forwarded-For'].split(',').first.strip
      else
        # Fallback to REMOTE_ADDR
        request.remote_ip
      end
    end
  end
end
