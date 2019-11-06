require 'db_spec_helper'

module StashDatacite
  describe GeolocationPoint do
    attr_reader :resource

    before(:each) do
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
    end

    describe '#from_resource_id' do
      it 'returns the points for the resource' do
        points = Array.new(3) do |index|
          point = GeolocationPoint.create(latitude: index, longitude: index)
          Geolocation.create(resource_id: resource.id, point_id: point.id)
          point
        end
        expect(GeolocationPoint.from_resource_id(resource.id)).to contain_exactly(*points)
      end
    end

    describe '#only_geo_points' do
      it 'returns the points with no boxes or places' do
        plain_points = Array.new(3) do |index|
          point = GeolocationPoint.create(latitude: index, longitude: index)
          Geolocation.create(resource_id: resource.id, point_id: point.id)
          point
        end
        Array.new(3) do |index|
          point = GeolocationPoint.create(latitude: index, longitude: index)
          place = GeolocationPlace.create(geo_location_place: "Place #{index}")
          box = GeolocationBox.create(sw_latitude: -index, ne_latitude: index, sw_longitude: -index, ne_longitude: index)
          Geolocation.create(resource_id: resource.id, point_id: point.id, place_id: place.id, box_id: box.id)
        end
        expect(GeolocationPoint.only_geo_points(resource.id)).to contain_exactly(*plain_points)
      end
    end

    describe '#bounding_box_str' do
      it 'returns a bounding box string for the point' do
        point = GeolocationPoint.create(latitude: 38.5816, longitude: -121.4944)
        expect(point.bounding_box_str).to eq('-121.4944 38.5816 -121.4944 38.5816')
      end
    end
  end
end
