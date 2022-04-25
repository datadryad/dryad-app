module StashEngine
  class EditHistory < ApplicationRecord
    self.table_name = 'stash_engine_edit_histories'
    belongs_to :resource, class_name: 'StashEngine::Resource', foreign_key: 'resource_id'

    amoeba do
      disable
    end
  end
end
