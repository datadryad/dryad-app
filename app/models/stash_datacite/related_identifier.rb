module StashDatacite
  class RelatedIdentifier < ActiveRecord::Base
    self.table_name = "dcs_related_identifiers"
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
