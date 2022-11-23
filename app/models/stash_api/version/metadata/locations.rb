# frozen_string_literal: true

require_relative 'metadata_item'

# bigdecimal is crappy and changes to strings https://github.com/rails/rails/issues/25017
# if we want them to appear like numbers then we have to to_f them.

module StashApi
  class Version
    class Metadata
      class Locations < MetadataItem

        def value
          @resource.geolocations.map do |geoloc|
            hsh = {}
            hsh.merge!(placename(geoloc)) if placename(geoloc)
            hsh.merge!(point(geoloc)) if point(geoloc)
            hsh.merge!(box(geoloc)) if box(geoloc)
            hsh
          end
        end

        private

        def placename(geolocation)
          p = geolocation.geolocation_place
          return { place: p.geo_location_place } unless p.blank?

          nil
        end

        def box(geolocation)
          b = geolocation.geolocation_box
          unless b.blank?
            return { box: {
              swLongitude: b&.sw_longitude&.to_f,
              swLatitude: b&.sw_latitude&.to_f,
              neLongitude: b&.ne_longitude&.to_f,
              neLatitude: b&.ne_latitude&.to_f
            } }
          end
          nil
        end

        def point(geolocation)
          p = geolocation.geolocation_point
          return { point: { latitude: p&.latitude&.to_f, longitude: p&.longitude&.to_f } } unless p.blank?

          nil
        end

      end
    end
  end
end
