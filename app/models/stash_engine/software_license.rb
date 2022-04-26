module StashEngine
  class SoftwareLicense < ActiveRecord::Base
    self.table_name = 'stash_engine_software_licenses'
    has_many :dataset_identifiers, class_name: 'StashEngine::Identifier'

  end
end
