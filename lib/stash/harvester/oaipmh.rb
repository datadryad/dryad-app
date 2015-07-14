require 'uri'
require 'oai/client'

module Stash
  module Harvester
    # Harvesting support for {http://www.openarchives.org/pmh/ OAI-PMH}
    module OAIPMH
      Dir.glob(File.expand_path('../oaipmh/*.rb', __FILE__), &method(:require))
    end
  end
end
