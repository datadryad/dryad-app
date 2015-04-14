require 'uri'
require 'oai/client'

module Stash
  module Harvester
    module OAI_PMH
      Dir.glob(File.expand_path('../oai_pmh/*.rb', __FILE__), &method(:require))
    end
  end
end
