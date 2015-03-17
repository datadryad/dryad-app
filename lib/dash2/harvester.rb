require 'uri'
require 'oai/client'

module Dash2
  module Harvester

    Dir.glob(File.expand_path('../harvester/*.rb', __FILE__), &method(:require))

  end
end
