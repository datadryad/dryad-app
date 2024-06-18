api_logger = ActiveSupport::Logger.new(Rails.root.join('log', 'api_requests.log'), 5, 10.megabytes)
api_logger.formatter = Logger::Formatter.new
api_logger.level = :debug
Rails.application.config.api_logger = api_logger

