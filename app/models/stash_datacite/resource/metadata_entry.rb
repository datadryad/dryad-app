# frozen_string_literal: true

module StashDatacite
  module Resource
    class MetadataEntry
      def initialize(resource, type, _tenant)
        @resource = resource
        @type = type
        create_publisher
        ensure_license
        @resource.fill_blank_author!
        ensure_author_orcid
      end

      def resource_type
        @resource_type = ResourceType
          .create_with(resource_id: @resource.id, resource_type: @type, resource_type_general: @type)
          .find_or_create_by(resource_id: @resource.id)
      end

      def title
        @title = @resource.title
      end

      def new_author
        @author = StashEngine::Author.new(resource_id: @resource.id)
      end

      def authors
        @authors = StashEngine::Author.where(resource_id: @resource.id)
      end

      def abstract
        @abstract = Description.type_abstract.find_or_create_by(resource_id: @resource.id)
      end

      def methods
        @methods = Description.type_methods.find_or_create_by(resource_id: @resource.id)
      end

      def technical_info
        @technical_info = Description.type_technical_info.find_or_create_by(resource_id: @resource.id)
      end

      def other
        @other = Description.type_other.find_or_create_by(resource_id: @resource.id)
      end

      def new_subject
        @subject = Subject.new
      end

      def subjects
        @subjects = @resource.subjects.non_fos
      end

      def new_contributor
        @contributor = Contributor.new(resource_id: @resource.id)
      end

      def contributors
        @contributors = Contributor.where(resource_id: @resource.id).where(contributor_type: :funder)
      end

      def contributor_groupings
        @contributor_groupings = ContributorGrouping.all
      end

      def new_related_identifier
        @related_identifier = RelatedIdentifier.new(resource_id: @resource.id)
      end

      def related_identifiers
        @related_identifiers = RelatedIdentifier.where(resource_id: @resource.id)
      end

      def new_geolocation_point
        @geolocation = Geolocation.new(resource_id: @resource.id)
        @geolocation_point = @geolocation.build_geolocation_point
      end

      def geolocation_points
        @geolocation_points = GeolocationPoint.only_geo_points(@resource.id)
      end

      def new_geolocation_box
        @geolocation = Geolocation.new(resource_id: @resource.id)
        @geolocation_box = @geolocation.build_geolocation_box
      end

      def geolocation_boxes
        @geolocation_boxes = GeolocationBox.only_geo_bbox(@resource.id)
      end

      def new_geolocation_place
        @geolocation = Geolocation.new(resource_id: @resource.id)
        @geolocation_place = @geolocation.build_geolocation_place
      end

      def geolocation_places
        @geolocation_places = GeolocationPlace.from_resource_id(@resource.id)
      end

      def new_temporal_coverage
        @temporal_coverage = TemporalCoverage.new(resource_id: @resource.id)
      end

      def temporal_coverages
        @temporal_coverage = TemporalCoverage.where(resource_id: @resource.id)
      end

      private

      def ensure_license
        return unless @resource.rights.empty?

        license = StashEngine::License.by_id(@resource.identifier.license_id)
        @resource.rights.create(rights: license[:name], rights_uri: license[:uri])
      end

      def create_publisher
        publisher = Publisher.where(resource_id: @resource.id).first
        @publisher = publisher.present? ? publisher : Publisher.create(publisher: 'Dryad', resource_id: @resource.id)
      end

      # ensures that one author has the orcid of the owner of this dataset
      def ensure_author_orcid
        return if @resource.owner_author # the owner is already represented by an author with their orcid

        user = @resource.user

        this_author = @resource.authors.where(author_first_name: user.first_name, author_last_name: user.last_name).first

        if this_author.present?
          this_author.update(author_orcid: user.orcid)
          return
        end

        StashEngine::Author.create(
          author_first_name: user.first_name,
          author_last_name: user.last_name,
          author_orcid: user.orcid,
          author_email: user.email,
          resource_id: @resource.id
        )
      end
    end
  end
end
