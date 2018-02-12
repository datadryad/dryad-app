# frozen_string_literal: true

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
              'swLongitude': b.sw_longitude,
              'swLatitude': b.sw_latitude,
              'neLongitude': b.ne_longitude,
              'neLatitude': b.ne_latitude
            } }
          end
          nil
        end

        def point(geolocation)
          p = geolocation.geolocation_point
          return { point: { latitude: p.latitude, longitude: p.longitude } } unless p.blank?
          nil
        end

      end
    end
  end
end
