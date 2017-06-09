module StashDatacite
  class Format < ActiveRecord::Base
    self.table_name = 'dcs_formats'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
