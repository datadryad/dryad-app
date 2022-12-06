module Stash
  module LinkOut
    Dir.glob(File.expand_path('link_out/*.rb', __dir__)).each(&method(:require))
  end
end
