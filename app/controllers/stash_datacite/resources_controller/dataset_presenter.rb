# Why do things this way?
# http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/
# http://www.jetthoughts.com/blog/tech/2014/08/14/cleaning-up-your-rails-views-with-view-objects.html
# monkeypatch true and false to_i to be 0 and 1
class FalseClass; def to_i; 0 end end
class TrueClass; def to_i; 1 end end

module StashDatacite
  class ResourcesController
    class DatasetPresenter
      attr_reader :resource

      delegate :created_at, :updated_at, to: :resource

      def initialize(resource)
        @resource = resource
      end

      def title
        return '[No title supplied]' if @resource.titles.count < 1
        @resource.titles.first.title
      end

      # according to https://dash.ucop.edu/xtf/search?smode=metadataBasicsPage
      # required fields are Title, Institution, Data type, Data Creator(s)
      def required_filled
        count = 0
        # get titles that are not blank or nil, to_i converts t/f to 1/0
        count += (@resource.titles.where.not(title: [nil, '']).count > 0).to_i

        # get institution count which is the creators' affiliations more than 0
        count += (@resource.creators.where.not(affliation_id: nil).count > 0).to_i

        # count if a resource type is set for resource
        count += (not @resource.resource_type.nil?).to_i

        # count if any data creator(s) are set
        count += (@resource.creators.count > 0).to_i
        count
      end

      def required_total
        4
      end

      # according to https://dash.ucop.edu/xtf/search?smode=metadataBasicsPage
      # optional fields are Date, Keywords, Abstract, Methods, Citations
      def optional_filled
        count = 0

        count += (@resource.dates.where.not(date: [nil, '']).count > 0).to_i
        count += (@resource.subjects.count > 0).to_i
        count += (@resource.descriptions.where(description_type: 'abstract').count > 0).to_i
        count += (@resource.descriptions.where(description_type: 'methods').count > 0).to_i
        count
      end

      def optional_total
        5
      end

      def files
        @resource.clean_uploads
        @resource.file_uploads.count
      end
    end
  end
end
