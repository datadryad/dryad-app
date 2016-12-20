require 'db_spec_helper'

module StashDatacite
  describe Geolocation do
    attr_reader :resource

    before(:each) do
      user = StashEngine::User.create(
        uid: 'lmuckenhaupt-example@example.edu',
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
    end

    describe '#new_geolocation' do
      before(:each) do
        Geolocation.new_geolocation(
          resource_id: resource.id,
          place: 'Los Angeles',
          point: [34.2635, -118.2955],
          box: [32.8007, -118.9448, 34.8233, -117.6462]
        )
      end
      it 'creates a location' do
        geolocations = resource.geolocations
        expect(geolocations.count).to eq(1)
      end
      it 'creates a place' do
        place = resource.geolocations.first.geolocation_place
        expect(place).not_to be_nil
        expect(place.geo_location_place).to eq('Los Angeles')
      end
      it 'creates a point' do
        point = resource.geolocations.first.geolocation_point
        expect(point).not_to be_nil
        expect(point.latitude).to eq(34.2635)
        expect(point.longitude).to eq(-118.2955)
      end
      it 'creates a box' do
        box = resource.geolocations.first.geolocation_box
        expect(box).not_to be_nil
        expect(box.sw_latitude).to eq(32.8007)
        expect(box.sw_longitude).to eq(-118.9448)
        expect(box.ne_latitude).to eq(34.8233)
        expect(box.ne_longitude).to eq(-117.6462)
      end
    end

    # describe 'amoeba copy' do
    #
    # end
  end
end
