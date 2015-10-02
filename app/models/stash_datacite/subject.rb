module StashDatacite
  class Subject < ActiveRecord::Base
    self.table_name = "dcs_subjects"
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
