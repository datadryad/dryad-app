module StashDatacite
  class Title < ActiveRecord::Base
    self.table_name = "dcs_titles"
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
