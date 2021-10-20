# Initialize json formatter for rails_semantic_logger
#
# per https://github.com/reidmorrison/rails_semantic_logger/issues/73
#

#Rails.application.config.rails_semantic_logger.format = :json
Rails.application.config.rails_semantic_logger.add_file_appender = false
Rails.application.config.semantic_logger.add_appender(file_name: 'log/json.log', formatter: :json)

# this doesnt work. I suppose we can't yet access Rails.env???
#Rails.application.config.semantic_logger.add_appender(file_name: "log/#{Rails.env}.log", formatter: :json)



