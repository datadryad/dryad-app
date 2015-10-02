module StashDatacite
  class Description < ActiveRecord::Base
    self.table_name = "dcs_descriptions"
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
