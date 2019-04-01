require 'serrano'
# this sets up the serrano config, the gem for connecting to crossref API
# https://www.rubydoc.info/gems/serrano
Serrano.configuration do |config|
  config.base_url = APP_CONFIG.crossref_base_url
  byebug
  config.mailto = APP_CONFIG.crossref_mailto
end
