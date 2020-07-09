module StashDatacite
  class ResourcesController
    class PdfMetadata
      # include StashDatacite::ResourcesHelper
      attr_reader :resource, :identifier

      def initialize(resource, identifier, citation)
        @resource = resource
        @identifier = identifier
        @citation = citation
      end

      def top_left
        return @citation if @citation.length < 60

        "#{@citation[0..@citation.rindex(' ', 60)].strip} ..."
      end

      def top_right
        @identifier.to_s
      end

      def bottom_left
        @resource.try(:publisher).try(:publisher) || ''
      end

      def bottom_right
        'Page [page] of [topage]'
      end

      private

      def h(item)
        ERB::Util.html_escape(item)
      end
    end
  end
end
