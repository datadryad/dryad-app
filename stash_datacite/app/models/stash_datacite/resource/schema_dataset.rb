# frozen_string_literal: true

require 'json'
module StashDatacite
  module Resource
    # this class creates a schema.org dataset structure that can be output as json+ld or others
    # https://developers.google.com/search/docs/data-types/datasets
    # https://schema.org/Dataset
    class SchemaDataset # rubocop:disable Metrics/ClassLength
      ITEMS_TO_ADD = {
        'name' => :names,
        'description' => :descriptions,
        'url' => :url,
        'sameAs' => :same_as,
        'version' => :version,
        'keywords' => :keywords,
        'creator' => :authors,
        'includedInDataCatalog' => :included_in_data_catalog,
        'distribution' => :distribution,
        'temporalCoverage' => :temporal_coverages,
        'spatialCoverage' => :spatial_coverages,
        'citation' => :citation,
        'license' => :license
      }.freeze

      def initialize(resource:, citation:, landing:)
        @resource = resource
        @citation = citation
        @landing = landing
      end

      def generate
        structure = { '@context' => 'http://schema.org', '@type' => 'dataset' }
        ITEMS_TO_ADD.each_pair do |k, v|
          item = to_item(send(v))
          structure[k] = item if item
        end
        structure
      end

      private

      def to_item(value)
        return unless value
        return value unless value.class == Array
        value.length == 1 ? value.first : value
      end

      def names
        return [] if @resource.title.blank?
        [@resource.title]
      end

      def descriptions
        return [] unless @resource.descriptions
        @resource.descriptions.map(&:description).compact
      end

      # google says URLs of the Location of a page describing the dataset
      def url
        # the url should be the dx.doi, this seems like view logic
        "https://doi.org/#{@resource.try(:identifier).try(:identifier)}"
      end

      def same_as
        @landing
      end

      def version
        @resource.try(:stash_version).try(:version)
      end

      def keywords
        return [] unless @resource.subjects
        @resource.subjects.map(&:subject).compact
      end

      def authors
        return [] unless @resource.authors
        @resource.authors.map do |i|
          { '@type' => 'Person', 'givenName' => i.author_first_name, 'familyName' => i.author_last_name }
        end
      end

      def included_in_data_catalog
        'https://merritt.cdlib.org'
      end

      def distribution
        return nil unless @resource.download_uri
        { '@type' => 'DataDownload', 'fileFormat' => 'application/zip', 'contentURL' => @resource.download_uri }
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

      attr_reader :citation

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
