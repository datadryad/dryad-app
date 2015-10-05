require 'stash/harvester'

module Stash
  module Harvester
    # Harvesting support for {http://www.openarchives.org/pmh/ OAI-PMH}
    class Application
      Dir.glob(File.expand_path('../application/*.rb', __FILE__), &method(:require))
    end
  end
end
