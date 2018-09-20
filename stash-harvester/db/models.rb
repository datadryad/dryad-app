module Stash
  # A gem for harvesting metadata from a digital repository for indexing
  module Harvester
    Dir.glob(File.expand_path('models/*.rb', __dir__)).sort.each(&method(:require))
  end
end
