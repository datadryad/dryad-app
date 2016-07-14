module StashDatacite
  class RelatedIdentifier < ActiveRecord::Base
    self.table_name = 'dcs_related_identifiers'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :related_identifier_type
    belongs_to :relation_type

    before_save :strip_whitespace

    # TODO: we are creating bad DataCite by saving a grant number as a related identifier without a type and it is
    # also not a globally unique identifier, either.

    # this is to provide a useful message about the related identifier
    def to_s
      related_id_type = "#{related_identifier_type.try(:related_identifier_type)}"
      "This dataset #{relation_type.try(:friendly_relation_name)} #{related_id_type}: #{related_identifier}"
    end

    private
    def strip_whitespace
      self.related_identifier = self.related_identifier.strip unless self.related_identifier.nil?
    end
  end
end
