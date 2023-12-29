class ApiLoggerMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if request.path.start_with?('/api')
      logger = Rails.application.config.api_logger

      logger.info('---')
      logger.info("Path: #{request.path}")
      logger.info("Params: #{request.params}")
      logger.info("Body: #{request.body.read}")
    end

    @app.call(env)
  end
end
