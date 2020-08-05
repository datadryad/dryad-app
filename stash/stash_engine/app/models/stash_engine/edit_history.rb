module StashEngine
  class EditHistory < ApplicationRecord
    belongs_to :resource, class_name: 'StashEngine::Resource', foreign_key: 'resource_id'

    amoeba do
      disable
    end
  end
end
