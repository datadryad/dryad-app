# frozen_string_literal: true

# basing this structure on that suggested in http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/
# TODO: is this class really necessary? seems like we could add about four methods in resource_patch.rb and be done.
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
        @contributors = @resource.contributors.where(contributor_type: :funder)
      end

      def related_identifiers
        @related_identifiers = @resource.related_identifiers
      end

      def file_uploads
        @file_uploads = @resource.current_file_uploads
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

      def geolocation_data?
        geolocation_points.exists? || geolocation_places.exists? || geolocation_boxes.exists?
      end

      def temporal_coverages
        @temporal_coverages = TemporalCoverage.where(resource_id: @resource.id)
      end

      # TODO: is this actually used? it doesn't look like it
      def embargo
        @embargo = if @resource.embargo.present?
                     @resource.embargo
                   else
                     # TODO: and this looks especially fishy
                     StashEngine::Embargo.new
                   end
      end

      def share
        @share = if @resource.share.present?
                   @resource.share
                 else
                   StashEngine::Share.create(resource_id: @resource.id)
                 end
      end

      def pdf_filename
        # “surname_date_first_five_title_words.pdf” or “surname_et_al_date_first_five_title_words.pdf”,
        # where “surname” is the surname of the first author, “date” is the publication year, and
        # “first_five_title_words” are the first five whitespace-separated words of the dataset title.
        "#{pdf_author}_#{pdf_pub_year}_#{pdf_title}"
      end

      private

      def pdf_title
        title_str.split(' ')[0..4].join('_')
      end

      def pdf_pub_year
        @resource.try(:publication_years).try(:first).try(:publication_year) || ''
      end

      def pdf_author
        return "#{authors.first.author_last_name}_et_al" if authors.length > 1
        authors.try(:first).try(:author_last_name).to_s
      end
    end
  end
end
