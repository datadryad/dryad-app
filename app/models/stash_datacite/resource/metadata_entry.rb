# frozen_string_literal: true

module StashDatacite
  module Resource
    class MetadataEntry
      def initialize(resource, type, tenant)
        @resource = resource
        @type = type
        submitted = @resource.identifier.last_submitted_resource
        paying = tenant&.payment_configuration&.covers_dpc?
        @resource.update(tenant_id: tenant.id) if submitted.blank? || (paying && !submitted.tenant&.payment_configuration&.covers_dpc?)
        @resource.fill_blank_author!
        ensure_author_orcid
        ensure_license if @type == 'collection'
      end

      def resource_type
        @resource_type = ResourceType
          .create_with(resource_id: @resource.id, resource_type: @type, resource_type_general: @type)
          .find_or_create_by(resource_id: @resource.id)
      end

      def resource_publications
        @resource_publication = StashEngine::ResourcePublication.find_or_create_by(resource_id: @resource.id, pub_type: :primary_article)
        @primary_article = @resource.related_identifiers.where(work_type: 'primary_article').first || StashDatacite::RelatedIdentifier.new(
          resource_id: @resource.id, related_identifier_type: 'doi', work_type: 'primary_article'
        )
      end

      def descriptions
        @abstract = Description.type_abstract.find_or_create_by(resource_id: @resource.id)
        @methods = Description.type_methods.find_or_create_by(resource_id: @resource.id)
        @technical_info = Description.type_technical_info.find_or_create_by(resource_id: @resource.id)
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
        return if @resource.identifier.license_id.present?

        @resource.identifier.update(license_id: 'cc0')
      end

      # ensures that one author has the orcid of the owner of this dataset
      def ensure_author_orcid
        return if @resource.owner_author # the owner is already represented by an author with their orcid

        # ensure resource submitter exists
        @resource.submitter = @resource.creator.id unless @resource.submitter.present?
        user = @resource.submitter

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
