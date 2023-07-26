# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
require 'selenium-webdriver'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)

# Prevent database truncation if the environment is not test
abort('The Rails environment is running in production mode!') unless Rails.env.test?

require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Conveniently places a screenshot of the page into the tmp/ dir if a failure happens
require 'capybara-screenshot/rspec'
# Clear all of the screenshots from old tests
Dir[Rails.root.join('tmp/capybara/*')].each { |f| File.delete(f) }

# Do not allow rack-attack to limit the rate of requests during testing
Rack::Attack.enabled = false

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

Dir[Rails.root.join('spec/mocks/*.rb')].each { |f| require f }
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
Dir[Rails.root.join('spec/mixins/*.rb')].each { |f| require f }
Dir[Rails.root.join('lib/**/*.rb')].each { |f| require f }

# if you have precompiled assets, the tests will use them without telling you and they might be out of date
# this burned me with out of date and non-working javascript for an entire afternoon of aggravating debugging.  :evil-asset-pipeline:
dir = Rails.root.join('public/assets/')
FileUtils.rm_rf(dir)

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{Rails.root}/spec/fixtures"
  config.bisect_runner = :shell

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # force a rake run before test suite
  config.before(:suite) do
    output = `rake db:migrate`
    puts output
    require Rails.root.join('db/migrate/20211021173621_add_triggers_for_last_curation_activity.rb').to_s
    require Rails.root.join('db/migrate/20211020221956_add_triggers_for_latest_resource.rb').to_s

    %w[trigger_curation_insert trigger_curation_update trigger_curation_delete].each do |i|
      # result = ActiveRecord::Base.connection.execute("show triggers like '%#{i}%'")
      ActiveRecord::Base.connection.execute("AddTriggersForLastCurationActivity::#{i.upcase}".constantize)
    rescue ActiveRecord::StatementInvalid => e
      raise e unless e.to_s.include?('Trigger already exists')
    end

    %w[trigger_resource_insert trigger_resource_update trigger_resource_delete].each do |i|
      ActiveRecord::Base.connection.execute("AddTriggersForLatestResource::#{i.upcase}".constantize)
    rescue ActiveRecord::StatementInvalid => e
      raise e unless e.to_s.include?('Trigger already exists')
    end

    # result = ActiveRecord::Base.connection.execute("show triggers like '%curation%'") and result.to_a.length shows number
  end

  config.include React::Rails::TestHelper
end
