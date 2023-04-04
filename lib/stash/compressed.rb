module Stash
  module Compressed
    class Error < StandardError; end
    Dir.glob(File.expand_path('compressed/*.rb', __dir__)).each(&method(:require))
  end
end
