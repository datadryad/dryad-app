module StashEngine
  class Identifier < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'
  end
end
