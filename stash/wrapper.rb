module Stash
  # Code relating to the {https://dash.ucop.edu/stash_wrapper/ Stash wrapper format}
  module Wrapper
    Dir.glob(File.expand_path('wrapper/*.rb', __dir__)).each(&method(:require))
  end
end
