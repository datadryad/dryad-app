# basing this structure on that suggested in http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/
# TODO: is this class really necessary? seems like we could add about four methods in resource_patch.rb and be done.
module StashDatacite
  module Resource
    class Review
      def initialize(resource)
        @resource = resource
      end

      def title
        @resource.titles.where(title_type: nil).first
      end

      def title_str
        title.title
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

      def no_geolocation_data
        geolocation_points.empty? && geolocation_places.empty? && geolocation_boxes.empty? ? true : false
      end

      def embargo
        if @resource.embargo.present?
          @embargo = @resource.embargo
        else
          @embargo = StashEngine::Embargo.new
        end
      end

      def share
        if @resource.share.present?
          @share = @resource.share
        else
          @share = StashEngine::Share.create(resource_id: @resource.id)
        end
      end

      def pdf_filename
        # “surname_date_first_five_title_words.pdf” or “surname_et_al_date_first_five_title_words.pdf”,
        # where “surname” is the surname of the first author, “date” is the publication year, and
        # “first_five_title_words” are the first five whitespace-separated words of the dataset title.
        author = ''
        if authors.length > 1
          author = "#{authors.first.author_last_name}_et_al"
        else
          author = "#{authors.try(:first).try(:author_last_name)}"
        end
        pub_year = @resource.try(:publication_years).try(:first).try(:publication_year) || ''

        shorter_title = title_str.split(' ')[0..4].join('_')

        "#{author}_#{pub_year}_#{shorter_title}"
      end
    end
  end
end
