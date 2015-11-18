module StashDatacite
  class RelationType < ActiveRecord::Base
    self.table_name = 'dcs_relation_types'
    has_one :related_identifier
  end
end
