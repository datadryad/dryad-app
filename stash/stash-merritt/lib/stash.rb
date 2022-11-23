require 'logger'

module Stash
  Dir.glob(File.expand_path('stash/*.rb', __dir__)).each(&method(:require))
end
