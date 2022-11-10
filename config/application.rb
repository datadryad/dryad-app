require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine" 
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dash2
  class Application < Rails::Application
    # Initialize configuration defaults for the Rails version.
    config.load_defaults 6.0
    config.autoload_paths << Rails.root.join("lib")
    Rails.autoloaders.main.ignore("#{Rails.root}/app/overrides")

    config.generators.javascript_engine = :js

    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc

    config.active_job.queue_adapter = :delayed_job

    # Do not compare the origin of HTTP requests with the current state of the request.
    # Our Apache config changes HTTPS to HTTP when contacting Passenger, so the origin
    # will not be the same.
    config.action_controller.forgery_protection_origin_check = false

    # ryan used this in some manuscript parsing and gem updates break it.  See
    # https://stackoverflow.com/questions/72970170/upgrading-to-rails-6-1-6-1-causes-psychdisallowedclass-tried-to-load-unspecif
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
