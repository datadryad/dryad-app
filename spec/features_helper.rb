require 'rails_helper'
require 'capybara/dsl'
require 'capybara/rails'
require 'capybara/rspec'

# ############################################################
# Capybara config

Capybara.register_driver(:selenium) do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.javascript_driver = :chrome

Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.default_driver = :selenium
end

# ------------------------------------------------------------
# Additional RSpec configuration

RSpec.configure do |config|
  # Treat specs in features/ as feature specs
  config.infer_spec_type_from_file_location!

  # TODO: figure out how to move some of this to stash_discovery
  require 'solr_wrapper'
  config.before(:all) do
    @solr = SolrWrapper.instance(port: '8983')
    @solr.start
    begin
      @collection = @solr.create(dir: 'spec/config/solr/conf', name: 'geoblacklight')
    rescue => ex
      puts ex
      @solr.stop
      @solr = nil
    end
  end

  config.after(:all) do
    begin
      @solr.delete(@collection) if @collection
    ensure
      @solr.stop if @solr
    end
  end
end

