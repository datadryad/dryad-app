module StashDatacite
  class Date < ActiveRecord::Base
    self.table_name = 'dcs_dates'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
