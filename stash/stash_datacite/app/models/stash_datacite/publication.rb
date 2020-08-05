module StashDatacite
  class Publication < ApplicationRecord
    self.table_name = 'stash_engine_internal_data'
    belongs_to :stash_identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
  end
end
