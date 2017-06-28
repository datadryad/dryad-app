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
# Solr config

# TODO: figure out how to move some of this to stash_discovery

require 'solr_wrapper'
require 'colorize'

def info(msg)
  puts msg.to_s.colorize(:blue)
end

def warn(msg)
  puts msg.to_s.colorize(:red)
end

def solr_start
  info 'Starting Solr'
  @solr = SolrWrapper.instance(port: '8983', version: '5.2.1')
  @solr.start
  info 'Solr 5.2.1 started on port 8983'
  begin
    @collection = @solr.create(dir: 'spec/config/solr/conf', name: 'geoblacklight')
    info 'geoblacklight collection created'
  rescue => ex
    warn ex
    @solr.stop
    @solr = nil
  end
end

def solr_stop
  @solr.delete(@collection) if @collection
ensure
  @solr.stop if @solr
end

# ------------------------------------------------------------
# Additional RSpec configuration

RSpec.configure do |config|
  # Treat specs in features/ as feature specs
  config.infer_spec_type_from_file_location!

  config.before(:all) { solr_start }
  config.after(:all) { solr_stop }
end
