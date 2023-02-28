module Stash
  module Merritt
    # this causes barfing
    # Dir.glob(File.expand_path('merritt/*.rb', __dir__)).sort.each(&method(:require))
    require_relative 'merritt/module_info'
    require_relative 'merritt/object_manifest_package'
    require_relative 'merritt/repository'
    require_relative 'merritt/submission_job'
    require_relative 'merritt/merritt_helper'
    require_relative '../../../../lib/stash/doi/id_gen'
    require_relative '../../../../lib/stash/doi/ezid_gen'
    require_relative '../../../../lib/stash/doi/datacite_gen'
  end
end
