module StashEngine
  class Embargo < ApplicationRecord
    belongs_to :resource, class_name: 'StashEngine::Resource'
    include StashEngine::Concerns::ResourceUpdated
  end
end
