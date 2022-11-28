# frozen_string_literal: true

require 'json'
require 'stash/import/crossref'

module StashDatacite
  module Resource
    # this class creates a schema.org dataset structure that can be output as json+ld or others
    # https://developers.google.com/search/docs/data-types/datasets
    # https://schema.org/Dataset
    class SchemaDataset
      ITEMS_TO_ADD = {
        '@id' => :doi_url,
        'name' => :names,
        'description' => :descriptions,
        'url' => :landing_url,
        'contentUrl' => :content_urls,
        'identifier' => :doi_url,
        'version' => :version,
        'isAccessibleForFree' => :true_val,
        'keywords' => :keywords,
        'creator' => :authors,
        'distribution' => :distribution,
        'temporalCoverage' => :temporal_coverages,
        'spatialCoverage' => :spatial_coverages,
        'citation' => :citation,
        'license' => :license,
        'publisher' => :publisher,
        'provider' => :provider
      }.freeze

      def initialize(resource:)
        @resource = resource
      end

      def generate
        structure = { '@context' => 'http://schema.org', '@type' => 'Dataset' }
        ITEMS_TO_ADD.each_pair do |k, v|
          item = to_item(send(v))
          structure[k] = item if item
        end
        structure
      end

      private

      def true_val
        true
      end

      def publisher
        {
          '@id': 'https://datadryad.org',
          '@type': 'Organization',
          'legalName': 'Dryad Data Platform',
          'name': 'Dryad',
          'url': 'https://datadryad.org'
        }.compact
      end

      def provider
        {
          '@id': 'https://datadryad.org'
        }.compact
      end

      def to_item(value)
        return unless value
        return value unless value.instance_of?(Array)

        value.length == 1 ? value.first : value
      end

      def names
        return [] if @resource.title.blank?

        [@resource.clean_title]
      end

      def descriptions
        return [] unless @resource.descriptions

        @resource.descriptions.map do |d|
          str = ActionView::Base.full_sanitizer.sanitize(d.description || '')
          ((str&.length || 0) > 1000 ? "#{str[0..1000]}..." : str)
        end.compact
      end

      def landing_url
        target_id = CGI.escape(@resource.identifier&.to_s)
        Rails.application.routes.url_helpers.show_url(target_id)
      end

      # These are urls for the individual files for download.
      # It's much more problematic to add the zip file since creating these zip files is an expensive and slow operation
      # taken care of by Merritt (who doesn't really enjoy the extra load) and often results in queueing, javascript
      # progress-bars and all kinds of gymnatics to avoid all the problems.
      #
      # It seems that full zip files aren't going away as a requirement but have their issues.  If we wanted to make them
      # instantly available then we'd probably also want to increase our storage costs by a lot and make them available
      # as instant downloads and store the zip files pre-created in S3 or elsewhere.
      def content_urls
        return [] unless @resource.file_view

        @resource.data_files.present_files.map { |f| Rails.application.routes.url_helpers.download_stream_url(f.id) }
      end

      def doi_url
        "https://doi.org/#{@resource.try(:identifier).try(:identifier)}"
      end

      def version
        @resource.try(:stash_version).try(:version)
      end

      def keywords
        return [] unless @resource.subjects.non_fos

        @resource.subjects.non_fos.map(&:subject).compact
      end

      def authors
        return [] unless @resource.authors

        @resource.authors.map do |i|
          orcid = i.author_orcid
          affiliation = i.affiliation
          author_hash = {
            '@type' => 'Person',
            'name' => i.author_standard_name,
            'givenName' => i.author_first_name,
            'familyName' => i.author_last_name
          }.compact
          author_hash[:sameAs] = "http://orcid.org/#{orcid}" if orcid
          if affiliation
            author_hash[:affiliation] = {
              '@type' => 'Organization',
              'sameAs' => affiliation.ror_id,
              'name' => affiliation.smart_name
            }.compact
          end
          author_hash
        end
      end

      def distribution
        target_id = CGI.escape(@resource.identifier&.to_s)
        download_url = Rails.application.routes.url_helpers.download_dataset_url(target_id)
        return nil unless download_url

        {
          '@type' => 'DataDownload',
          'encodingFormat' => 'application/zip',
          'contentUrl' => download_url
        }
      end

      def temporal_coverages
        ((@resource.publication_years ? @resource.publication_years.map(&:publication_year) : []) +
            (@resource.datacite_dates ? @resource.datacite_dates.map(&:date) : []) +
            TemporalCoverage.where(resource_id: @resource.id).to_a.map(&:temporal_coverages)).compact
      end

      def spatial_coverages
        places = []
        points = []
        boxes = []
        @resource.geolocations.each do |geo|
          places << geo.geolocation_place
          points << geo.geolocation_point
          boxes << geo.geolocation_box
        end
        (convert_places(places) + convert_points(points) + convert_boxes(boxes))
      end

      def convert_places(places)
        places.compact.map(&:geo_location_place)
      end

      def convert_boxes(boxes)
        # must use this form instead of compact! since it returns nil in that form sometimes
        boxes.compact.map do |box|
          { '@type' => 'Place',
            'geo' => {
              '@type' => 'GeoShape',
              'box' => "#{box.ne_latitude} #{box.ne_longitude} #{box.sw_latitude} #{box.sw_longitude}"
            } }
        end
      end

      def convert_points(points)
        # must use this form instead of compact! since it returns nil in that form sometimes
        points.compact.map do |point|
          { '@type' => 'Place',
            'geo' => {
              '@type' => 'GeoCoordinates',
              'latitude' => point.latitude,
              'longitude' => point.longitude
            } }
        end
      end

      def citation
        return unless @resource.identifier&.publication_article_doi

        article_doi = Stash::Import::Crossref.bare_doi(doi_string: @resource.identifier.publication_article_doi)
        "http://doi.org/#{article_doi}"
      end

      def license
        return [] unless @resource.rights

        @resource.rights.map do |right|
          { '@type' => 'CreativeWork',
            'name' => right.rights,
            'license' => right.rights_uri }
        end
      end
    end
  end
end
