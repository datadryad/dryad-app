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
        @resource.stash_version
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
        @file_uploads = @resource.current_file_uploads
      end

      def image_uploads
        @image_uploads = @resource.image_uploads
      end

      def geolocation_points
        @geolocation_points = GeolocationPoint.only_geo_points(@resource.id)
      end

      def geolocation_boxes
        @geolocation_boxes = GeolocationBox.only_geo_bbox(@resource.id)
      end

      def geolocation_places
        @geolocation_places = GeolocationPlace.from_resource_id(@resource.id)
      end

      def publisher
        @publisher = @resource.publisher
      end

      def no_geolocation_data
        (geolocation_points.length < 1 && geolocation_places.length < 1 && geolocation_boxes.length < 1) ? true : false
      end
    end
  end
end
