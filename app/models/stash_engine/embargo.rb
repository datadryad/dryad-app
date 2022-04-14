module StashEngine
  class Embargo < ApplicationRecord
    belongs_to :resource, class_name: 'StashEngine::Resource'
  end
end
