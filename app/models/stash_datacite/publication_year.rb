module StashDatacite
  class PublicationYear < ActiveRecord::Base
    self.table_name = 'dcs_publication_years'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
