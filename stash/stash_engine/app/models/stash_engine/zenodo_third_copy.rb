module StashEngine
  class ZenodoThirdCopy < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier'
    belongs_to :resource, class_name: 'StashEngine::Resource'

  end
end
