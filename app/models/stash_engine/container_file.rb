module StashEngine
  class ContainerFile < ApplicationRecord
    self.table_name = 'stash_engine_container_files'
    belongs_to :data_file, class_name: 'StashEngine::DataFile'
  end
end
