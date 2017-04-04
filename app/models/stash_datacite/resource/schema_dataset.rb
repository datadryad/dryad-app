require 'json'
module StashDatacite
  module Resource
    # this class creates a schema.org dataset structure that can be output as json+ld or others
    # https://developers.google.com/search/docs/data-types/datasets
    # https://schema.org/Dataset
    class SchemaDataset
      def initialize(resource:, citation:, landing:)
        @resource = resource
        @citation = citation
        @landing = landing
      end

      def generate
        items_to_add = {
            'name'                    => :names,
            'description'             => :descriptions,
            'url'                     => :url,
            'sameAs'                  => :same_as,
            'version'                 => :version,
            'keywords'                => :keywords,
            'creator'                 => :creators,
            'includedInDataCatalog'   => :included_in_data_catalog,
            'distribution'            => :distribution,
            'temporalCoverage'        => :temporal_coverages,
            'spatialCoverage'         => :spatial_coverages,
            'citation'                => :citation,
            'license'                 => :license
        }
        structure = {'@context' => 'http://schema.org', '@type' => 'dataset'}
        items_to_add.each_pair do |k, v|
          result = send(v)
          if result.class == Array
            if result.length == 1
              structure[k] = result.first
            elsif result.length > 1
              structure[k] = result
            end
          else
            structure[k] = result if result
          end
        end
        structure
      end

      private

      def names
        return [] unless @resource.titles
        @resource.titles.map(&:title).compact
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

      def creators
        return [] unless @resource.creators
        @resource.creators.map do |i|
          {'@type' => 'Person', 'givenName' => i.author_first_name, 'familyName' => i.author_last_name }
        end
      end

      def included_in_data_catalog
        'https://merritt.cdlib.org'
      end

      def distribution
        return nil unless @resource.download_uri
        {'@type' => 'DataDownload', 'fileFormat' => 'application/zip', 'contentURL' => @resource.download_uri }
      end

      def temporal_coverages
        ((@resource.publication_years ? @resource.publication_years.map(&:publication_year) : []) +
            (@resource.datacite_dates ? @resource.datacite_dates.map(&:date) : [] )).compact
      end

      def spatial_coverages
        places, points, boxes = [], [], []
        @resource.geolocations.each do |geo|
          places << geo.geolocation_place
          points << geo.geolocation_point
          boxes << geo.geolocation_box
        end
        # must use this form instead of compact! since it returns nil in that form sometimes
        places = places.compact.map(&:geo_location_place)
        points = points.compact.map do |point|
          { '@type' => 'Place',
            'geo' => {
                '@type'     => 'GeoCoordinates',
                'latitude'  => point.latitude,
                'longitude' => point.longitude
            }
          }
        end
        boxes = boxes.compact.map do |box|
          { '@type' => 'Place',
            'geo' => {
                '@type'     => 'GeoShape',
                'box'     => "#{box.ne_latitude} #{box.ne_longitude} #{box.sw_latitude} #{box.sw_longitude}"
            }
          }
        end
        (places + points + boxes)
      end

      def citation
        @citation
      end

      def license
        return [] unless @resource.rights
        @resource.rights.map do |right|
          { '@type' => 'CreativeWork',
            'name' => right.rights,
            'license' => right.rights_uri
          }
        end
      end
    end
  end
end
