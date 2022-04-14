module StashEngine
  class Version < ApplicationRecord
    belongs_to :resource, class_name: 'StashEngine::Resource'
  end
end
