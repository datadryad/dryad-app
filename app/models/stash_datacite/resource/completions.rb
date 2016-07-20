# basing this structure on that suggested in http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/

# also
# monkeypatch true and false to_i to be 0 and 1
class FalseClass
  def to_i
    0
  end
end
class TrueClass
  def to_i
    1
  end
end

module StashDatacite
  module Resource
    class Completions
      def initialize(resource)
        @resource = resource
      end

      # these are the required ones and return true/false if completed
      def title
        @resource.titles.where.not(title: [nil, '']).count > 0
      end

      def institution
        @resource.creators.where.not(affiliation_id: nil).count > 0
      end

      def data_type
        !@resource.resource_type.nil?
      end

      def creator
        num_creators = @resource.creators.count
        return false if num_creators < 1
        @resource.creators.filled.count == num_creators  # the completely filled in creators must equal number of creators
      end

      def abstract
        @resource.descriptions.where(description_type: 'abstract').where.not(description: [nil, '']).count > 0
      end

      def required_completed
        title.to_i + institution.to_i + data_type.to_i + creator.to_i + abstract.to_i
      end

      def required_total
        5
      end

      def creator_name
        num_creators = @resource.creators.count
        return false if num_creators < 1
        @resource.creators.names_filled.count == num_creators  # the completely filled in creators must equal number of creators
      end

      def creator_affiliation
        num_creators = @resource.creators.count
        return false if num_creators < 1
        @resource.creators.affiliation_filled.count == num_creators  # the completely filled in creators must equal number of creators
      end

      # these are optional (recommended) ones
      def date
        @resource.datacite_dates.where.not(date: [nil, '']).count > 0
      end

      def keyword
        @resource.subjects.where.not(subject: [nil, '']).count > 0
      end

      def method
        @resource.descriptions.where(description_type: 'methods').where.not(description: [nil, '']).count > 0
      end

      def citation
        @resource.related_identifiers.where.not(related_identifier: [nil, '']).count > 0
      end

      def optional_completed
        date.to_i + keyword.to_i + method.to_i + citation.to_i
      end

      def optional_total
        4
      end
    end
  end
end
