require 'mysql2'
require 'responders'
require 'leaflet-rails'
require 'wicked_pdf'
require 'datacite/mapping'
require 'kaminari'
module StashDatacite
  class Engine < ::Rails::Engine
    isolate_namespace StashDatacite
  end
end
