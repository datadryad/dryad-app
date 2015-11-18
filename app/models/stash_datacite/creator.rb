module StashDatacite
  class Creator < ActiveRecord::Base
    self.table_name = 'dcs_creators'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
