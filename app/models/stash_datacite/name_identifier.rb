module StashDatacite
  class NameIdentifier < ActiveRecord::Base
    self.table_name = 'dcs_name_identifiers'
    has_one :creator
    has_one :contributor
  end
end
