module Stash
  module ZenodoReplicate
    Dir.glob(File.expand_path('zenodo_replicate/*.rb', __dir__)).each(&method(:require))
  end
end
