module StashDatacite
  class Contributor < ActiveRecord::Base
    self.table_name = 'dcs_contributors'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :name_identifier

    enum contributor_type: { funder: 'funder' }
  end
end
