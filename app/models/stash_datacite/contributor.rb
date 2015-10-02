module StashDatacite
  class Contributor < ActiveRecord::Base
    self.table_name = "dcs_contributors"
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
