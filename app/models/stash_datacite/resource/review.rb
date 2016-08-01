# basing this structure on that suggested in http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/
module StashDatacite
  module Resource
    class Review
      def initialize(resource)
        @resource = resource
      end

      def title
        @resource.titles.where(title_type: nil).first
      end

      def resource_type
        @resource.resource_type
      end

      def creators
        @resource.creators
      end

      def version
        @resource.version
      end

      def identifier
        @resource.identifier
      end

      def abstract
        @abstract = @resource.descriptions.where(description_type: :abstract).first
      end

      def methods
        @methods = @resource.descriptions.where(description_type: :methods).first
      end

      def other
        @other = @resource.descriptions.where(description_type: :other).first
      end

      def subjects
        @subjects = @resource.subjects
      end

      def contributors
        @contributors = @resource.contributors
      end

      def related_identifiers
        @related_identifiers = @resource.related_identifiers
      end

      def file_uploads
        @file_uploads = @resource.file_uploads
      end

      def image_uploads
        @image_uploads = @resource.image_uploads
      end

      def geolocation_points
        @geolocation_points = @resource.geolocation_points
      end

      def geolocation_boxes
        @geolocation_boxes = @resource.geolocation_boxes
      end

      def geolocation_places
        @geolocation_places = @resource.geolocation_places
      end

      def publisher
        @publisher = @resource.publisher
      end
    end
  end
end
