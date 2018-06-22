module Stash
  module Sword
    Dir.glob(File.expand_path('sword/*.rb', __dir__)).sort.each(&method(:require))
  end
end
