require 'uri'
require 'oai/client'
require "stash/harvester/engine"

module Stash
  module Harvester
    Dir.glob(File.expand_path('../harvester/*.rb', __FILE__), &method(:require))
  end
end
