require 'datacite/mapping'
require 'cgi'

# This file and classes are based on David's stash-harvester class and mostly the 'datacite_extensions.rb' which is
# most of the functionality we need, but we need it to come from the database instead of the returned stash-wrapper.xml
# file which we give to Merritt and it gives back to us.
#
# The methods are the same names for duck-typing should we ever need it (most likely we won't).  I also added a few
# additional methods for some missing fields that needed very little translation in the old code.  Also the to_index_document
# came from another class, but it's the only method we need from that class.
#
# The Datacite::Mapping patches extra methods into an external gem David wrote to make classes for every enum and they
# are used to special-sauce output for SOLR and geoblacklight's schema.

# these patch datacite mapping modules for some extra stuff David added
module Datacite
  module Mapping

    DATACITE_NAMESPACES = [DATACITE_3_NAMESPACE, DATACITE_4_NAMESPACE].freeze
    DATACITE_NAMESPACE_URIS = DATACITE_NAMESPACES.map(&:uri).freeze

    def self.datacite_namespace?(elem)
      (ns = elem.namespace) && DATACITE_NAMESPACE_URIS.include?(ns)
    end

    class Description
      def funding?
        # TODO: Make 'data were created with' etc. a constant or something and move it to Datacite::Mapping
        type == DescriptionType::OTHER && value.start_with?('Data were created with funding')
      end

      def usage?
        type == DescriptionType::OTHER && !funding?
      end
    end

    class GeoLocationBox
      # Expresses the coordinates of this `GeoLocationBox` in [OpenGIS Well-Known Text](http://www.opengeospatial.org/standards/sfa)
      # `ENVELOPE` format: `ENVELOPE(minX, maxX, maxY, minY)`. As the [Solr docs](https://cwiki.apache.org/confluence/display/solr/Spatial+Search)
      # say: "The parameter ordering is unintuitive but that's what the spec calls for."
      # @return [String] the coordinates of this box as a WKT `ENVELOPE`
      def to_envelope
        "ENVELOPE(#{west_longitude}, #{east_longitude}, #{north_latitude}, #{south_latitude})"
      end
    end

    class Identifier
      def to_doi
        "doi:#{value}"
      end
    end
  end
end

module Stash
  module Indexer
    class IndexingResource

      DESCRIPTION_TYPES_TO_DB = { Datacite::Mapping::DescriptionType::ABSTRACT => 'abstract',
                                  Datacite::Mapping::DescriptionType::METHODS => 'methods',
                                  Datacite::Mapping::DescriptionType::OTHER => 'other' }.freeze

      # takes a database resource object.
      def initialize(resource:)
        @resource = resource
      end

      # this is really what we want to get out of this for solr indexing, the rest is for compatibility with old indexing
      def to_index_document
        georss = calc_bounding_box
        {
          uuid: doi,
          dc_identifier_s: doi,
          dc_title_s: default_title,
          dc_creator_sm: creator_names.map(&:strip),
          dc_type_s: type,
          dc_description_s: description_text_for(Datacite::Mapping::DescriptionType::ABSTRACT).to_s.strip,
          dc_subject_sm: subjects,
          dct_spatial_sm: geo_location_places,
          georss_box_s: (georss ? georss.to_s : nil),
          solr_geom: bounding_box_envelope,
          solr_year_i: publication_year,
          dct_issued_dt: issued_date,
          dc_rights_s: license_name,
          dc_publisher_s: publisher,
          dct_temporal_sm: dct_temporal_dates,
          dryad_related_publication_name_s: related_publication_name,
          dryad_related_publication_id_s: related_publication_id,
          dryad_author_affiliation_name_sm: author_affiliations,
          dryad_author_affiliation_id_sm: author_affiliation_ids,
          dryad_dataset_file_ext_sm: dataset_file_exts,
          dcs_funder_sm: dataset_funders,
          updated_at_dt: updated_at_str
        }
      end

      def default_title
        @resource&.title&.strip
      end

      def doi
        @resource&.identifier&.to_s
      end

      def type
        # This is something like 'Software'
        @resource&.resource_type&.resource_type_general_friendly
      end

      def general_type
        # This is class like Datacite::Mapping::ResourceTypeGeneral
        @resource&.resource_type&.resource_type_general_mapping_obj
      end

      def creator_names
        authors = @resource.authors
        return [] if authors.empty?

        authors.map(&:author_full_name).reject(&:blank?)
      end

      def subjects
        @resource.subjects.non_fos.map { |s| s.subject&.strip }.reject(&:blank?)
      end

      def publication_year
        @resource.publication_years&.first&.publication_year&.to_i
      end

      def issued_date
        @resource&.publication_date&.utc&.iso8601
      end

      def license_name
        # we could make this call nicer by adding an association (or simulating one) on identifier
        StashEngine::License.by_id(@resource.identifier.license_id)[:name]
      end

      def publisher
        @resource&.publisher&.publisher
      end

      def grant_number
        @resource.contributors.where(contributor_type: 'funder').map(&:award_number).reject(&:blank?).map(&:strip).join("\r")
      end

      def usage_notes
        description_text_for(Datacite::Mapping::DescriptionType::OTHER)
      end

      # called like resource.description_text_for(DescriptionType::ABSTRACT).to_s.strip
      # I believe this returns the test for things besides usage notes
      def description_text_for(type)
        the_type = DESCRIPTION_TYPES_TO_DB[type]
        return nil unless the_type

        @resource.descriptions.where(description_type: the_type).map(&:description)
          .reject(&:blank?).map { |i| fix_html(i) }.join("\r")
      end

      # gives array of names
      def geo_location_places
        @resource.geolocations.map(&:geolocation_place).compact.map(&:geo_location_place).reject(&:blank?)
      end

      # using the icky datacite mapping objects
      def geo_location_boxes
        @resource.geolocations.map(&:geolocation_box).compact.map { |i| db_box_to_dc_mapping(db_box: i) }.compact
      end

      def geo_location_points
        @resource.geolocations.map(&:geolocation_point).compact.map { |i| db_point_to_dc_mapping(db_point: i) }.compact
      end

      def self.datacite?
        true
        # elem.name == 'resource' && Datacite::Mapping.datacite_namespace?(elem)
      end

      def calc_bounding_box
        lat_min, lat_max, long_min, long_max = nil
        geo_location_points.each do |pt|
          lat_min = [lat_min, pt.latitude].compact.min
          lat_max = [lat_max, pt.latitude].compact.max
          long_min = [long_min, pt.longitude].compact.min
          long_max = [long_max, pt.longitude].compact.max
        end
        geo_location_boxes.each do |box|
          lat_min = [lat_min, box.south_latitude, box.north_latitude].compact.min
          lat_max = [lat_max, box.south_latitude, box.north_latitude].compact.max
          long_min = [long_min, box.west_longitude, box.east_longitude].compact.min
          long_max = [long_max, box.west_longitude, box.east_longitude].compact.max
        end
        Datacite::Mapping::GeoLocationBox.new(lat_min, long_min, lat_max, long_max) if lat_min && long_min && lat_max && long_max
      end

      # converts to DublinCore Terms, temporal, see http://journal.code4lib.org/articles/9710 or
      # https://github.com/geoblacklight/geoblacklight-schema and seems very similar to the annotation going
      # into the original DataCite element.  https://terms.tdwg.org/wiki/dcterms:temporal
      #
      # method takes the values supplied and also adds every year for a range so people can search for
      # any of those years which may not be explicitly named
      def dct_temporal_dates
        items = @resource.datacite_dates.map(&:date).reject(&:blank?)
        items.map! do |dt|

          Date.iso8601(dt)&.strftime('%Y-%m-%d')
        rescue ArgumentError
          nil

        end
        items.compact

        # the below is the old stuff.  We don't have ranges in our dates.
        # items = dates.map(&:to_s).compact
        # year_range_items = dates.map do |i|
        #   (i.range_start.year..i.range_end.year).to_a.map(&:to_s) if i.range_start && i.range_end && i.range_start.year && i.range_end.year
        # end
        # (items + year_range_items).compact.flatten.uniq
      end

      def bounding_box_envelope
        (bbox = calc_bounding_box) ? bbox.to_envelope : nil
      end

      def related_publication_name
        @resource.identifier.internal_data.where(data_type: 'publicationName').first&.value
      end

      def related_publication_id
        ids = @resource.identifier.internal_data.where(data_type: %w[manuscriptNumber pubmedID])&.map(&:value)&.join(' ')
        pub_doi = @resource.related_identifiers.where(related_identifier_type: 'doi', work_type: 'primary_article').last
        (pub_doi.present? ? "#{ids} #{pub_doi.related_identifier}" : ids)
      end

      # rubocop:disable Style/MultilineBlockChain
      def author_affiliations
        @resource.authors.map do |author|
          author.affiliations.map(&:long_name)
        end.flatten.reject(&:blank?).uniq.reject { |elem| elem == ',' }
      end
      # rubocop:enable Style/MultilineBlockChain

      def author_affiliation_ids
        @resource.authors.map do |author|
          author.affiliations.map(&:ror_id)
        end.flatten.reject(&:blank?).uniq
      end

      def dataset_file_exts
        @resource.data_files.present_files.map do |df|
          File.extname(df.upload_file_name.to_s).gsub(/^./, '').downcase
        end.flatten.reject(&:blank?).uniq
      end

      def dataset_funders
        # Also do we only want to add items with valid FundRef entries?
        contrib_names = @resource.contributors.funder.completed.map(&:contributor_name)
        contrib_names << group_funders
        contrib_names.flatten.reject(&:blank?).uniq
      end

      # see how many group funders belong to each relevant group in the ContributorGrouping table and return additional
      # contributor names if we have an encompassing contributor that wants to be credited for its underling funders
      def group_funders
        extra_funders = []
        StashDatacite::ContributorGrouping.where(contributor_type: 'funder').each do |group|
          identifier_ids = group.json_contains.map { |i| i['name_identifier_id'] }
          count = @resource.contributors.funder.completed.where(name_identifier_id: identifier_ids).count
          extra_funders.push(group.contributor_name) if count.positive?
        end
        extra_funders
      end

      def updated_at_str
        # for solr, dates must follow ISO 8601 format
        @resource.updated_at.iso8601
      end

      private

      # helpers to convert to datacite mapping
      def db_box_to_dc_mapping(db_box:)
        return nil unless db_box.sw_latitude && db_box.ne_latitude && db_box.sw_longitude && db_box.ne_longitude

        Datacite::Mapping::GeoLocationBox.new(db_box.sw_latitude.to_f, db_box.sw_longitude.to_f, db_box.ne_latitude.to_f, db_box.ne_longitude.to_f)
      end

      def db_point_to_dc_mapping(db_point:)
        return nil unless db_point.latitude && db_point.longitude

        Datacite::Mapping::GeoLocationPoint.new(db_point.latitude.to_f, db_point.longitude.to_f)
      end

      def fix_html(my_str)
        CGI.unescapeHTML(Loofah.fragment(my_str).text.strip)
      end
    end
  end
end
