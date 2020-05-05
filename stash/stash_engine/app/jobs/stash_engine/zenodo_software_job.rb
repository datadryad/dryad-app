require 'stash/zenodo_replicate'

module StashEngine
  class ZenodoSoftwareJob < ::ActiveJob::Base
    queue_as :zenodo_software
    # TODO: this is a stub
  end
end

