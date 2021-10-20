# Initialize json formatter for rails_semantic_logger
#
# per https://github.com/reidmorrison/rails_semantic_logger/issues/73
#

config.semantic_logger.add_appender(file_name: "log/#{Rails.env}.json", formatter: :json)

