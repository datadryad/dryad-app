require 'uri'
require 'oai/client'

module Stash
  module Harvester
    module OAIPMH
      Dir.glob(File.expand_path('../oaipmh/*.rb', __FILE__), &method(:require))
    end
  end
end
