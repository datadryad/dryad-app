module Stash
  module Merritt
    Dir.glob(File.expand_path('../package/*.rb', __FILE__)).sort.each(&method(:require))
  end
end
