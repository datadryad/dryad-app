module StashApi
  class DatasetParser
    class Locations < StashApi::DatasetParser::BaseParser

      # Example of locations
      # "locations": [
      #   {
      #     "place": "Grogan's Mill, USA",
      #     "point": {
      #       "latitude": "30.130379",
      #       "longitude": "-95.402929"
      #     },
      #     "box": {
      #       "swLongitude": "-95.527852",
      #       "swLatitude": "30.049326",
      #       "neLongitude": "-95.32743",
      #       "neLatitude": "30.164696"
      #     }
      #   }
      # ]

      def parse
        clear
        return if @hash['locations'].blank?

        @hash['locations'].each do |location|
          data_maker(location)
        end
      end

      private

      def clear
        @resource.geolocations.destroy_all
      end

      def number?(item)
        true if Float(item)
      rescue ArgumentError, TypeError
        false
      end

      def valid_latitude?(item)
        return false unless number?(item)

        numval = Float(item)
        return true if numval <= 90.0 && numval >= -90.0

        false
      end

      def valid_longitude?(item)
        return false unless number?(item)

        numval = Float(item)
        return true if numval <= 180.0 && numval >= -180.0

        false
      end

      def valid_place?(item)
        ''.instance_of?(item.class) # string
      end

      def valid_point?(item)
        return false if item.nil?

        valid_latitude?(item['latitude']) && valid_longitude?(item['longitude'])
      end

      def valid_box?(item)
        return false if item.nil?

        valid_latitude?(item['swLatitude']) && valid_longitude?(item['swLongitude']) &&
            valid_latitude?(item['neLatitude']) && valid_longitude?(item['neLongitude'])
      end

      def make_place(location)
        return StashDatacite::GeolocationPlace.create(geo_location_place: location['place']) if valid_place?(location['place'])

        nil
      end

      def make_point(location)
        if valid_point?(location['point'])
          return StashDatacite::GeolocationPoint.create(
            latitude: Float(location['point']['latitude']),
            longitude: Float(location['point']['longitude'])
          )
        end
        nil
      end

      def make_box(location)
        if valid_box?(location['box'])
          return StashDatacite::GeolocationBox.create(
            sw_latitude: Float(location['box']['swLatitude']),
            sw_longitude: Float(location['box']['swLongitude']),
            ne_latitude: Float(location['box']['neLatitude']),
            ne_longitude: Float(location['box']['neLongitude'])
          )
        end
        nil
      end

      def data_maker(location)
        my_place = make_place(location)
        my_point = make_point(location)
        my_box = make_box(location)
        return if my_place.nil? && my_point.nil? && my_box.nil?

        StashDatacite::Geolocation.create(
          resource_id: @resource.id,
          place_id: my_place&.id,
          point_id: my_point&.id,
          box_id: my_box&.id
        )
      end

    end
  end
end
