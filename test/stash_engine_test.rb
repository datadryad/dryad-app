require 'test_helper'

#require File.expand_path("../dummy/config/environment", __FILE__)

class StashEngineTest < ActiveSupport::TestCase
  StashEngine.setup do |config|
    #fn = File.join(Rails.root, '..', '..', 'test', 'files', 'ucop.yml')
    #config.tenants = {:cdl => HashWithIndifferentAccess.new(YAML.load_file(fn))}
    #require_relative 'dummy/config/initializers/00_tenants'
    #require_relative 'dummy/config/initializers/app_config'
    #config.tenants = TENANT_CONFIG
    #config.app = APP_CONFIG
  end

  test 'truth' do
    assert_kind_of Module, StashEngine, 'module test'
  end
end
