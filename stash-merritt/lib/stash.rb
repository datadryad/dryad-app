require 'logger'

module Stash
  Dir.glob(File.expand_path('../stash/*.rb', __FILE__)).sort.each(&method(:require))
end
