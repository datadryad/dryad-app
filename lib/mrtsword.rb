module Mrtsword
  Dir.glob(File.expand_path('../mrtsword/*.rb', __FILE__)).sort.each(&method(:require))
end
