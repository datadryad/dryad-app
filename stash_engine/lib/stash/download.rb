Dir.glob(File.expand_path('download/*.rb', __dir__)).sort.each(&method(:require))
module Stash
  module Download

  end
end