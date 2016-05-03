module Stash
  module Sword
    Dir.glob(File.expand_path('../sword2/*.rb', __FILE__)).sort.each(&method(:require))
  end
end
