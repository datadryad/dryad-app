module StashDatacite
  class AlternateIdentifier < ActiveRecord::Base
    self.table_name = 'dcs_alternate_identifiers'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
