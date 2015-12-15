module StashDatacite
  class Embargo < ActiveRecord::Base
    self.table_name = 'dcs_embargoes'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    enum embargo_type: { no_value: 'none', download: 'download', description: 'description' }
  end
end
