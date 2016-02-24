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
      end

      def title
        return '[No title supplied]' if @resource.titles.count < 1
        @resource.titles.first.title
      end

      def required_filled
        0
      end

      def required_total
        0
      end

      def optional_filled
        0
      end

      def optional_total
        0
      end

      def files
        @resource.clean_uploads
        @resource.file_uploads.count
      end

    end
  end
end
