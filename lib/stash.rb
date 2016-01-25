module Stash
  Dir.glob(File.expand_path('../stash/*.rb', __FILE__), &method(:require))
end
