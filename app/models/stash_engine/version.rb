module StashEngine
  class Version < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'
  end
end
