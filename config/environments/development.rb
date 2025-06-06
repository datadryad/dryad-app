Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  # this craziness is to get logging both to console and to log file just like normal development
  # normal_logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
  # console_logger = ActiveSupport::Logger.new(STDOUT)
  # combined_logger = console_logger.extend(ActiveSupport::Logger.broadcast(normal_logger))
  #
  # combined_logger.formatter = config.log_formatter
  # config.logger = ActiveSupport::TaggedLogging.new(combined_logger)

  # this is so that we can still see output to console, otherwise it gets turned off for some reason with this environment and webrick
  # config.middleware.insert_before(Rails::Rack::Logger, Rails::Rack::LogTailer)
  config.log_level = :debug

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Store uploaded files on the local file system (see config/storage.yml for options)
  # config.active_storage.service = :local

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Do not email users
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true

  Rails.application.default_url_options = { host: 'localhost', port: 3000}
  Rack::Attack.enabled = false
  config.hosts.clear
end
