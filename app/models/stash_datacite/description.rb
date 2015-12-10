module StashDatacite
  class Description < ActiveRecord::Base
    self.table_name = 'dcs_descriptions'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    enum description_type: { abstract: 0, methods: 1, usage_notes: 2 }

    # scopes for description_type
    scope :type_abstract, -> { where(description_type: 0) }
    scope :type_methods, -> { where(description_type: 1) }
    scope :type_usage_notes, -> { where(description_type: 2) }
  end
end
