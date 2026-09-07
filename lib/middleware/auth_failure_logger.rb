module Middleware
  class AuthFailureLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      status, headers, body = @app.call(env)

      AuthFailureService.new(request, nil, get_params(request)).create(:api_unauthorized) if request.path == '/oauth/token' && status == 401

      [status, headers, body]
    rescue StandardError => e
      Rails.logger.error("AuthFailureLogger error: #{e.message}")
    end

    def get_params(request)
      request.params.except('password')
    end
  end
end
