module Stash
  module Repo
    # The name of this gem
    NAME = 'stash-repo'.freeze

    # The version of this gem
    VERSION = '0.0.1'.freeze

    # The copyright notice for this gem
    COPYRIGHT = 'Copyright (c) 2017 The Regents of the University of California'.freeze

    Dir.glob(File.expand_path('repo/*.rb', __dir__)).each(&method(:require))
  end
end
