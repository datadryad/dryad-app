module StashDatacite
  class Right < ActiveRecord::Base
    self.table_name = 'dcs_rights'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
