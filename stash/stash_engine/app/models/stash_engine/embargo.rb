module StashEngine
  class Embargo < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'
    include StashEngine::Concerns::ResourceUpdated
  end
end
