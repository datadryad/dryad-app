module StashDatacite
  module Resource
    class MetadataEntry
      def initialize(resource, tenant)
        @resource = resource
        ensure_license(tenant)
      end

      def resource_type
        @resource_type = ResourceType.find_or_create_by(resource_id: @resource.id, resource_type: 'dataset')
      end

      def title
        @title = Title.where(resource_id: @resource.id).first_or_initialize
      end

      def new_creator
        @creator = Creator.new(resource_id: @resource.id)
      end

      def creators
        @creators = Creator.where(resource_id: @resource.id)
      end

      def abstract
        @abstract = Description.type_abstract.find_or_create_by(resource_id: @resource.id)
      end

      def methods
        @methods = Description.type_methods.find_or_create_by(resource_id: @resource.id)
      end

      def usage_notes
        @usage_notes = Description.type_usage_notes.find_or_create_by(resource_id: @resource.id)
      end

      def new_subject
        @subject = Subject.new
      end

      def subjects
        @subjects = @resource.subjects
      end

      def new_contributor
        @contributor = Contributor.new(resource_id: @resource.id)
      end

      def contributors
        @contributors = Contributor.where(resource_id: @resource.id)
      end

      def new_related_identifier
        @related_identifier = RelatedIdentifier.new(resource_id: @resource.id)
      end

      def related_identifiers
        @related_identifiers = RelatedIdentifier.where(resource_id: @resource.id)
      end

      def new_geolocation_point
        @geolocation_point = GeolocationPoint.new(resource_id: @resource.id)
      end

      def geolocation_points
        @geolocation_points = GeolocationPoint.where(resource_id: @resource.id)
      end

      def new_geolocation_box
        @geolocation_box = GeolocationBox.new(resource_id: @resource.id)
      end

      def geolocation_boxes
        @geolocation_boxes = GeolocationBox.where(resource_id: @resource.id)
      end

      def new_geolocation_place
        @geolocation_place = GeolocationPlace.new(resource_id: @resource.id)
      end

      def geolocation_places
        @geolocation_places = GeolocationPlace.where(resource_id: @resource.id)
      end

      private
      def ensure_license(tenant)
        if @resource.rights.empty?
          license = StashEngine::License.by_id(tenant.default_license)
          @resource.rights.create(rights: license[:name],
                                 rights_uri: license[:uri])
        end
      end
    end
  end
end
