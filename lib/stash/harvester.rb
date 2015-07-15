module Stash
  # A gem for harvesting metadata from a digital repository for indexing
  module Harvester
    Dir.glob(File.expand_path('../harvester/*.rb', __FILE__), &method(:require))
  end
end
