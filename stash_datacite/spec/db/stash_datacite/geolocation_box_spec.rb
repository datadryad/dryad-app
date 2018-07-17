require 'db_spec_helper'

module StashDatacite
  describe GeolocationBox do
    attr_reader :resource

    before(:each) do
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
    end

    describe '#from_resource_id' do
      it 'returns the boxes for the resource' do
        boxes = Array.new(3) do |index|
          box = GeolocationBox.create(sw_latitude: -index, ne_latitude: index, sw_longitude: -index, ne_longitude: index)
          Geolocation.create(resource_id: resource.id, box_id: box.id)
          box
        end
        expect(GeolocationBox.from_resource_id(resource.id)).to contain_exactly(*boxes)
      end
    end

    describe '#only_geo_bbox' do
      it 'returns the boxes with no boxes or places' do
        plain_boxes = Array.new(3) do |index|
          box = GeolocationBox.create(sw_latitude: -index, ne_latitude: index, sw_longitude: -index, ne_longitude: index)
          Geolocation.create(resource_id: resource.id, box_id: box.id)
          box
        end
        Array.new(3) do |index|
          point = GeolocationPoint.create(latitude: index, longitude: index)
          place = GeolocationPlace.create(geo_location_place: "Place #{index}")
          box = GeolocationBox.create(sw_latitude: -index, ne_latitude: index, sw_longitude: -index, ne_longitude: index)
          Geolocation.create(resource_id: resource.id, point_id: point.id, place_id: place.id, box_id: box.id)
        end
        expect(GeolocationBox.only_geo_bbox(resource.id)).to contain_exactly(*plain_boxes)
      end
    end

    describe '#bounding_box_str' do
      it 'returns a bounding box string for the box' do
        box = GeolocationBox.create(sw_longitude: -121.5605, ne_longitude: -121.3627, sw_latitude: 38.4378, ne_latitude: 38.6856)
        expect(box.bounding_box_str).to eq('-121.5605 38.4378 -121.3627 38.6856')
      end
    end
  end
end
