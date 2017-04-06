module StashDatacite
  class Format < ActiveRecord::Base
    self.table_name = 'dcs_formats'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
