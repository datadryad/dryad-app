module StashDatacite
  class Publisher < ActiveRecord::Base
    self.table_name = 'dcs_publishers'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
