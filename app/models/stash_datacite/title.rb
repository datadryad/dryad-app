module StashDatacite
  class Title < ActiveRecord::Base
    self.table_name = 'dcs_titles'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    enum title_type: { main: 0, subtitle: 1 }
  end
end
