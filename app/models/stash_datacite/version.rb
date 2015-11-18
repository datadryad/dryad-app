module StashDatacite
  class Version < ActiveRecord::Base
    self.table_name = 'dcs_versions'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
