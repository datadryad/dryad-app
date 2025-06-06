Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # force_ssl causes infinite redirects, only do in apache or rails, not both
  # config.force_ssl = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files). x
  config.require_master_key = true

  config.public_file_server.enabled = true

  # Compress JavaScripts and CSS, default is sassc without being specified for css
  config.assets.js_compressor = :terser

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Store uploaded files on the local file system (see config/storage.yml for options)
  # config.active_storage.service = :local     
  
  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = [I18n.default_locale]

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  logger = ActiveSupport::Logger.new(Rails.root.join("log", "stage.log"), 5, 10.megabytes)
  config.logger    = ActiveSupport::TaggedLogging.new(logger)

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  #this is obnoxious because the initializers haven't run yet, so have to duplicate code to read config
  # this will interpret any ERB in the yaml file first before bringing in
  ac = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'app_config.yml'))).result, aliases: true, permitted_classes: [Date])[Rails.env]

  unless ac['page_error_email'].blank?
    Rails.application.config.middleware.use ExceptionNotification::Rack,
      :email => {
          # :deliver_with => :deliver, # Rails >= 4.2.1 do not need this option since it defaults to :deliver_now
          :email_prefix => "[Drystg Exception]",
          :sender_address => %{"Dryad Notifier" <no-reply-dryad@sandbox.datadryad.org>},
          :exception_recipients => ac['page_error_email']
      },
      :error_grouping => true,
      :error_grouping_period => 3.hours,
      :ignore_exceptions => [
          'ActionController::InvalidAuthenticityToken',
          'ActionController::InvalidCrossOriginRequest',
          'URI::InvalidURIError'
        ] + ExceptionNotifier.ignored_exceptions,
      :ignore_crawlers => %w{Googlebot bingbot}
  end

  # Email through Amazon SES
  # Although it would be nice to read these settings from the APP_CONFIG,
  # that hash doesn't exist at the time this file is loaded, so we need to
  # put the configuration directly in here.
  ActionMailer::Base.smtp_settings = {
    :address => 'email-smtp.us-west-2.amazonaws.com',
    :port => '587',
    :authentication => :plain,
    :user_name => 'AKIA2KERHV5ERJHPR552',
    :password => Rails.application.credentials[Rails.env.to_sym][:aws_ses_password]
  }


  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  Rails.application.default_url_options = { host: 'sandbox.datadryad.org' }

end
