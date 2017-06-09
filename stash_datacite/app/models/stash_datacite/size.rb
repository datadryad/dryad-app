module StashDatacite
  class Size < ActiveRecord::Base
    self.table_name = 'dcs_sizes'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
