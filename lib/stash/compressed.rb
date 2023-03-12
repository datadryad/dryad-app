module Stash
  module Compressed
    Dir.glob(File.expand_path('compressed/*.rb', __dir__)).each(&method(:require))
  end
end
