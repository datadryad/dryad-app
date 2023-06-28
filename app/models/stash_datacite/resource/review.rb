# frozen_string_literal: true

# basing this structure on that suggested in http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/
# TODO: is this class really necessary? seems like we could add about four methods in resource_patch.rb and be done.
# Also, changed to cache many of these values in case they're called more than once (the ||= operator below)
module StashDatacite
  module Resource
    class Review
      def initialize(resource)
        @resource = resource
      end

      def title_str
        @resource.title
      end

      def resource_type
        @resource.resource_type
      end

      def authors
        @resource.authors
      end

      def version
        @resource.stash_version
      end

      def identifier
        @resource.identifier
      end

      def abstract
        @abstract ||= @resource.descriptions.where(description_type: :abstract).first
      end

      def methods
        @methods ||= @resource.descriptions.where(description_type: :methods).first
      end

      def other
        @other ||= @resource.descriptions.where(description_type: :other).first
      end

      def subjects
        @subjects = @resource.subjects.order(subject_scheme: :desc, subject: :asc)
      end

      def contributors
        @contributors ||= @resource.contributors.where(contributor_type: :funder).order(funder_order: :asc, id: :asc)
      end

      def related_identifiers
        @related_identifiers ||= @resource.related_identifiers
      end

      def file_uploads
        @file_uploads ||= @resource.current_file_uploads
      end

      def software_files
        @software_files ||= @resource.current_file_uploads(my_class: StashEngine::SoftwareFile)
      end

      def supp_files
        @supp_files ||= @resource.current_file_uploads(my_class: StashEngine::SuppFile)
      end

      def geolocation_points
        @geolocation_points ||= GeolocationPoint.only_geo_points(@resource.id)
      end

      def geolocation_boxes
        @geolocation_boxes ||= GeolocationBox.only_geo_bbox(@resource.id)
      end

      def geolocation_places
        @geolocation_places ||= GeolocationPlace.from_resource_id(@resource.id)
      end

      def publisher
        @publisher ||= @resource.publisher
      end

      def geolocation_data?
        geolocation_points.exists? || geolocation_places.exists? || geolocation_boxes.exists?
      end

      def temporal_coverages
        @temporal_coverages ||= TemporalCoverage.where(resource_id: @resource.id)
      end

      # TODO: is this actually used? it doesn't look like it
      def embargo
        @embargo ||= @resource.publication_date
      end

      def share
        @share ||=
          if @resource&.identifier&.shares&.present?
            @resource&.identifier&.shares&.first
          else
            StashEngine::Share.create(identifier_id: @resource.identifier.id)
          end
      end

    end
  end
end
