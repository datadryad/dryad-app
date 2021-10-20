# Initialize json formatter for rails_semantic_logger
#
# per https://github.com/reidmorrison/rails_semantic_logger/issues/73
#

Rails.application.config.rails_semantic_logger.format = :json
Rails.application.config.rails_semantic_logger.add_file_appender = false
Rails.application.config.semantic_logger.add_appender(file_name: 'log/json.log', formatter: :json)


#SemanticLogger.add_appender(file_name: 'json_formatter.json', formatter: :json)


