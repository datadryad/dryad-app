# Initialize rails_semantic_logger configs.
# See: https://logger.rocketjob.io/rails.html
#
# Disable default file_appender to fix issue with using multiple appenders.
# See: https://github.com/reidmorrison/rails_semantic_logger/issues/73
Rails.application.config.rails_semantic_logger.add_file_appender = false

# Additional 'log_tag' fields
Rails.application.config.log_tags = {
  request_id: :request_id,
  ip:         :remote_ip,
} 

