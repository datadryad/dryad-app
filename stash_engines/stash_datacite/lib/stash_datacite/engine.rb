require 'mysql2'
require 'responders'
require 'leaflet-rails'
require 'datacite/mapping'
require 'kaminari'
module StashDatacite
  class Engine < ::Rails::Engine
    isolate_namespace StashDatacite
  end
end
