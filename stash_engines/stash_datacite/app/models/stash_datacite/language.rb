module StashDatacite
  class Language < ActiveRecord::Base
    self.table_name = 'dcs_languages'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
