module StashDatacite
  class RelatedIdentifierType < ActiveRecord::Base
    self.table_name = "dcs_related_identifier_types"
    has_one :related_identifier
  end
end
