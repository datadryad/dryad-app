# See the StashEngine lib/stash_engine/engine.rb file for default values
# until this is more completed and better documented

StashEngine.setup do |config|
  config.tenants = TENANT_CONFIG
  config.app = APP_CONFIG
end