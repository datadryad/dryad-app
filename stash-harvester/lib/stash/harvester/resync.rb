require 'uri'
require 'oai/client'

module Stash
  module Harvester
    # Harvesting support for [ResourceSync](http://www.openarchives.org/rs/1.0/resourcesync)
    module Resync
      Dir.glob(File.expand_path('resync/*.rb', __dir__)).sort.each(&method(:require))
    end
  end
end
