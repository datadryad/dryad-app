module StashDatacite
  class RelatedIdentifier < ActiveRecord::Base
    self.table_name = 'dcs_related_identifiers'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :related_identifier_type
    belongs_to :relation_type

    before_save :strip_whitespace

    private
    def strip_whitespace
      self.related_identifier = self.related_identifier.strip unless self.related_identifier.nil?
    end
  end
end
