module StashEngine
  class ResourceUsage < ActiveRecord::Base
    belongs_to :resource
  end
end
