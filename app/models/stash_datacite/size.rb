module StashDatacite
  class Size < ActiveRecord::Base
    self.table_name = "dcs_sizes"
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
