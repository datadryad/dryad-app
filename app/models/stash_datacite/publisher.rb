module StashDatacite
  class Publisher < ActiveRecord::Base
    self.table_name = "dcs_publishers"
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
