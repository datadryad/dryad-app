class OAuthFailureLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    status, headers, body = @app.call(env)

    AuthFailureService.new(request, nil, request.params).create(:api_unauthorized) if request.path == '/oauth/token' && status == 401

    [status, headers, body]
  end
end
