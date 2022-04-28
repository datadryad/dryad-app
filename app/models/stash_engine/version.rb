module StashEngine
  class Version < ApplicationRecord
    self.table_name = 'stash_engine_versions'
    belongs_to :resource, class_name: 'StashEngine::Resource'
  end
end
