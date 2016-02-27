module StashDatacite
  class Subject < ActiveRecord::Base
    self.table_name = 'dcs_subjects'
    has_and_belongs_to_many :resources, class_name: StashDatacite.resource_class.to_s, through: 'StashDatacite::ResourceSubject'
  end
end
