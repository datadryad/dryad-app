module Stash
  module Sword
    Dir.glob(File.expand_path('sword/*.rb', __dir__)).each(&method(:require))
  end
end
