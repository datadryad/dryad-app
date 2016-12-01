# Why do things this way?
# http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/
# http://www.jetthoughts.com/blog/tech/2014/08/14/cleaning-up-your-rails-views-with-view-objects.html
module StashDatacite
  class ResourcesController
    class DatasetPresenter
      attr_reader :resource

      delegate :created_at, :updated_at, to: :resource

      def initialize(resource)
        @resource = resource
        @completions = Resource::Completions.new(@resource)
      end

      def title
        return '[No title supplied]' if @resource.titles.count < 1
        @resource.titles.first.title
      end

      def status
        @resource.current_resource_state_value
      end

      # according to https://dash.ucop.edu/xtf/search?smode=metadataBasicsPage
      # required fields are Title, Institution, Data type, Data Creator(s), Abstract
      def required_filled
        @completions.required_completed
      end

      def required_total
        @completions.required_total
      end

      # according to https://dash.ucop.edu/xtf/search?smode=metadataBasicsPage
      # optional fields are Date, Keywords, Methods, Citations
      def optional_filled
        @completions.optional_completed
      end

      def optional_total
        @completions.optional_total
      end

      def file_count
        @resource.current_file_uploads.count
      end

      def external_identifier
        id = @resource.identifier
        if id.blank?
          'bad_identifier'
        else
          "#{id.try(:identifier_type).try(:downcase)}:#{id.try(:identifier)}"
        end
      end
    end
  end
end
