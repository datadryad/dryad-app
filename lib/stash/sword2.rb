require 'uri'

module Stash
  module Sword2
    Dir.glob(File.expand_path('../sword2/*.rb', __FILE__)).sort.each(&method(:require))

  end
end
