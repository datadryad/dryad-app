require 'db_spec_helper'

module StashDatacite
  describe GeolocationPlace do
    attr_reader :resource

    before(:each) do
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
    end

    describe '#from_resource_id' do
      it 'returns the places for the resource' do
        places = Array.new(3) do |index|
          place = GeolocationPlace.create(geo_location_place: "Place #{index}")
          Geolocation.create(resource_id: resource.id, place_id: place.id)
          place
        end
        expect(GeolocationPlace.from_resource_id(resource.id)).to contain_exactly(*places)
      end
    end

    describe '#geo_places' do
      it 'returns an empty array if there are no places' do
        expect(GeolocationPlace.geo_places(resource.id)).to be_empty
      end

      it 'returns a hash with place names' do
        locations = Array.new(3) do |index|
          place = GeolocationPlace.create(geo_location_place: "Place #{index}")
          Geolocation.create(resource_id: resource.id, place_id: place.id)
        end
        expected = locations.map do |loc|
          { geolocation_place: loc.geolocation_place.geo_location_place }
        end
        expect(GeolocationPlace.geo_places(resource.id)).to eq(expected)
      end

      it 'returns a hash with place name and coordinates for each place with a point' do
        locations = Array.new(3) do |index|
          point = GeolocationPoint.create(latitude: index, longitude: index)
          place = GeolocationPlace.create(geo_location_place: "Place #{index}")
          Geolocation.create(resource_id: resource.id, point_id: point.id, place_id: place.id)
        end
        expected = locations.map do |loc|
          {
            geolocation_place: loc.geolocation_place.geo_location_place,
            latitude: loc.geolocation_point.latitude,
            longitude: loc.geolocation_point.longitude
          }
        end
        expect(GeolocationPlace.geo_places(resource.id)).to eq(expected)
      end
    end

    describe '#bounding_box_str' do
      it 'returns a bounding box string based on the point' do
        point = GeolocationPoint.create(latitude: 38.5816, longitude: -121.4944)
        place = GeolocationPlace.create(geo_location_place: 'Los Angeles')
        Geolocation.create(resource_id: resource.id, point_id: point.id, place_id: place.id)
        expect(place.bounding_box_str).to eq(point.bounding_box_str)
      end

      it 'returns a bounding box string based on the box' do
        box = GeolocationBox.create(sw_longitude: -121.5605, ne_longitude: -121.3627, sw_latitude: 38.4378, ne_latitude: 38.6856)
        place = GeolocationPlace.create(geo_location_place: 'Los Angeles')
        Geolocation.create(resource_id: resource.id, box_id: box.id, place_id: place.id)
        expect(place.bounding_box_str).to eq(box.bounding_box_str)
      end

      it 'returns nil if no box or point' do
        place = GeolocationPlace.create(geo_location_place: 'Los Angeles')
        Geolocation.create(resource_id: resource.id, place_id: place.id)
        expect(place.bounding_box_str).to be_nil
      end
    end
  end
end
