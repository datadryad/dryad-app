module StashEngine
  class SoftwareLicense < ActiveRecord::Base
    has_many :dataset_identifiers, class_name: 'StashEngine::Identifier'

  end
end
