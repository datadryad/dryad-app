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
    # TODO: is this class really necessary? as with Review, seems like we could just patch Resource
    # TODO: and we don't need most of these to return false or 0 when they can just return nil
    class Completions
      def initialize(resource)
        @resource = resource
      end

      # these are the required ones and return true/false if completed
      def title
        @resource.titles.where.not(title: [nil, '']).count > 0
      end

      def institution
        @resource.authors.joins(:affiliations).count > 0
      end

      def data_type
        !@resource.resource_type.nil?
      end

      def author_name
        num_authors = @resource.authors.count
        return false if num_authors < 1
        # the completely filled in authors must equal number of authors
        @resource.authors.names_filled.count == num_authors
      end

      def author_affiliation
        num_authors = @resource.authors.count
        return false if num_authors < 1
        # the completely filled in authors must equal number of authors
        @resource.authors.affiliation_filled.count == num_authors
      end

      def abstract
        @resource.descriptions.where(description_type: 'abstract').where.not(description: [nil, '']).count > 0
      end

      def required_completed
        title.to_i + author_affiliation.to_i + data_type.to_i + author_name.to_i + abstract.to_i
      end

      def required_total
        5
      end

      # these are optional (recommended) ones
      def date
        @resource.datacite_dates.where.not(date: [nil, '']).count > 0
      end

      def keyword
        @resource.subjects.where.not(subject: [nil, '']).count > 0
      end

      def method
        @resource.descriptions.where(description_type: 'methods').where
                 .not(description: [nil, '']).count > 0
      end

      # TODO: why is this called 'citation'?
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
