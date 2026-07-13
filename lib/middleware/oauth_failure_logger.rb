module Middleware
  class OauthFailureLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      status, headers, body = @app.call(env)

      AuthFailureService.new(request, nil, get_params(request)).create(:api_unauthorized) if request.path == '/oauth/token' && status == 401

      [status, headers, body]
    end

    def get_params(request)
      request.params.except('password')
    end
  end
end
