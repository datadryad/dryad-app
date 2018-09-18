require 'uri'
require 'oai/client'

module Stash
  module Harvester
    # Harvesting support for [OAI-PMH](http://www.openarchives.org/pmh/)
    module OAI
      Dir.glob(File.expand_path('oai/*.rb', __dir__)).sort.each(&method(:require))
    end
  end
end
