# Initialize json formatter for rails_semantic_logger
#
# per https://github.com/reidmorrison/rails_semantic_logger/issues/73
#

Rails.application.config.rails_semantic_logger.format = :json
#SemanticLogger.add_appender(file_name: 'json_formatter.json', formatter: :json)


