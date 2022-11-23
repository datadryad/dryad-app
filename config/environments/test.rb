require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Spring reloads the application code if something changes. In the test environment 
  # you need to enable reloading for that to work: 
  # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#spring-and-the-test-environment
  # config.cache_classes = false

  # However this causes our tests to fail for lack of initialization!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.

  # Rails suggests to not eager load code on boot. This avoids loading your whole application
  # However, according to 
  # https://bibwild.wordpress.com/2016/02/18/struggling-towards-reliable-capybara-javascript-testing/
  # it is important to do the eager_load to avoid problems with capybara.
  # TODO: This *might* be changeable in Rails5, but we need to try it out.
  config.eager_load = true
  config.allow_concurrency = false

  # Warn about pending migrations that have not been applied instead of just barfing and making all tests error.
  # In other words, return a useful error about migrations not being current.
  config.active_record.migration_error = true

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  
  # Enable caching for rack attack testing.
  #config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  Rails.application.default_url_options = { host: 'localhost', port: 3000 }
end
