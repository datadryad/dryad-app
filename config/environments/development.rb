Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Dryad's development environment is a little more stable than Rails assumes;
  # we use the local environment for truly quick-changing development work. Settings in this
  # file are a bit different from the defaults for that reason.
  
  config.cache_classes = true

  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store                       
  
  # Mailer
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: 'dryad-dev.cdlib.org' }
  
  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true
  
  # Suppress logger output for normal asset requests.
  config.assets.quiet = true   
  
  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker   
  
  Rails.application.default_url_options = { host: 'dryad-dev.cdlib.org' }

end
