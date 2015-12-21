require 'mysql2'
require 'jquery-rails'
require 'jquery-ui-rails'
require 'responders'
require 'leaflet-rails'
require 'datacite/mapping'
module StashDatacite
  class Engine < ::Rails::Engine
    isolate_namespace StashDatacite
  end
end
