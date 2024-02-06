# == Schema Information
#
# Table name: dcs_geo_locations
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  box_id      :integer
#  place_id    :integer
#  point_id    :integer
#  resource_id :integer
#
# Indexes
#
#  index_dcs_geo_locations_on_box_id       (box_id)
#  index_dcs_geo_locations_on_place_id     (place_id)
#  index_dcs_geo_locations_on_point_id     (point_id)
#  index_dcs_geo_locations_on_resource_id  (resource_id)
#
require 'rails_helper'

module StashDatacite
  describe Geolocation do

    before(:each) do
      user = create(:user,
                    email: 'lmuckenhaupt@example.edu',
                    tenant_id: 'dataone')
      @resource = create(:resource, user: user)
    end

    describe '#new_geolocation' do
      before(:each) do
        @loc = Geolocation.new_geolocation(
          resource_id: @resource.id,
          place: 'Los Angeles',
          point: [34.2635, -118.2955],
          box: [32.8007, -118.9448, 34.8233, -117.6462]
        )
      end
      it 'creates a location' do
        geolocations = @resource.geolocations
        expect(geolocations.count).to eq(1)
        expect(geolocations).to contain_exactly(@loc)
      end
      it 'creates a place' do
        place = @resource.geolocations.first.geolocation_place
        expect(place).not_to be_nil
        expect(place.geo_location_place).to eq('Los Angeles')
      end
      it 'creates a point' do
        point = @resource.geolocations.first.geolocation_point
        expect(point).not_to be_nil
        expect(point.latitude).to eq(34.2635)
        expect(point.longitude).to eq(-118.2955)
      end
      it 'creates a box' do
        box = @resource.geolocations.first.geolocation_box
        expect(box).not_to be_nil
        expect(box.sw_latitude).to eq(32.8007)
        expect(box.sw_longitude).to eq(-118.9448)
        expect(box.ne_latitude).to eq(34.8233)
        expect(box.ne_longitude).to eq(-117.6462)
      end
    end

    describe '#amoeba_dup' do
      before(:each) do
        loc = Geolocation.new_geolocation(
          resource_id: @resource.id,
          place: 'Los Angeles',
          point: [34.2635, -118.2955],
          box: [32.8007, -118.9448, 34.8233, -117.6462]
        )
        @new_loc = loc.amoeba_dup
      end
      it 'duplicates the place' do
        place = @new_loc.geolocation_place
        expect(place).not_to be_nil
        expect(place.geo_location_place).to eq('Los Angeles')
      end
      it 'duplicates the point' do
        point = @new_loc.geolocation_point
        expect(point).not_to be_nil
        expect(point.latitude).to eq(34.2635)
        expect(point.longitude).to eq(-118.2955)
      end
      it 'duplicates the box' do
        box = @new_loc.geolocation_box
        expect(box).not_to be_nil
        expect(box.sw_latitude).to eq(32.8007)
        expect(box.sw_longitude).to eq(-118.9448)
        expect(box.ne_latitude).to eq(34.8233)
        expect(box.ne_longitude).to eq(-117.6462)
      end
    end

    describe 'destroy methods' do
      before(:each) do
        @loc = Geolocation.new_geolocation(
          resource_id: @resource.id,
          place: 'Los Angeles',
          point: [34.2635, -118.2955],
          box: [32.8007, -118.9448, 34.8233, -117.6462]
        )
      end
      it 'destroys a place' do
        @loc.destroy_place
        expect(@loc.geolocation_place).to be_nil
      end
      it 'destroys a point' do
        @loc.destroy_point
        expect(@loc.geolocation_point).to be_nil
      end
      it 'destroys a box' do
        @loc.destroy_box
        expect(@loc.geolocation_box).to be_nil
      end
      it 'destroys itself when empty' do
        @loc.destroy_place
        @loc.destroy_point
        @loc.destroy_box
        expect(@loc.instance_variable_get(:@destroyed)).to eq(true)
      end
    end

    describe '#datacite_mapping_place' do
      it 'returns the place' do
        loc = Geolocation.new_geolocation(
          resource_id: @resource.id,
          place: 'Los Angeles',
          point: [34.2635, -118.2955],
          box: [32.8007, -118.9448, 34.8233, -117.6462]
        )
        expect(loc.datacite_mapping_place).to eq('Los Angeles')
      end

      it 'returns nil for no place' do
        loc = Geolocation.new_geolocation(
          resource_id: @resource.id,
          point: [34.2635, -118.2955],
          box: [32.8007, -118.9448, 34.8233, -117.6462]
        )
        expect(loc.datacite_mapping_place).to be_nil
      end
    end

    describe 'datacite_mapping_point' do
      it 'returns the point' do
        loc = Geolocation.new_geolocation(
          resource_id: @resource.id,
          place: 'Los Angeles',
          point: [34.2635, -118.2955],
          box: [32.8007, -118.9448, 34.8233, -117.6462]
        )
        dc_point = loc.datacite_mapping_point
        expect(dc_point).not_to be_nil
        expect(dc_point.latitude).to eq(34.2635)
        expect(dc_point.longitude).to eq(-118.2955)
      end

      it 'returns nil for missing points' do
        loc = Geolocation.new_geolocation(
          resource_id: @resource.id,
          place: 'Los Angeles',
          box: [32.8007, -118.9448, 34.8233, -117.6462]
        )
        dc_point = loc.datacite_mapping_point
        expect(dc_point).to be_nil
      end

      it 'returns nil for bad points' do
        points = [[34.2635, nil], [nil, -118.2955]]
        points.each do |pt|
          loc = Geolocation.new_geolocation(
            resource_id: @resource.id,
            place: 'Los Angeles',
            point: pt,
            box: [32.8007, -118.9448, 34.8233, -117.6462]
          )
          dc_point = loc.datacite_mapping_point
          expect(dc_point).to be_nil
        end
      end
    end

    describe '#datacite_mapping_box' do
      before(:each) do
        @loc = Geolocation.new_geolocation(
          resource_id: @resource.id,
          box: [32.8007, -118.9448, 34.8233, -117.6462]
        )
        @box = @loc.geolocation_box
      end
      it 'returns the box' do
        expected = Datacite::Mapping::GeoLocationBox.new(
          32.8007, -118.9448, 34.8233, -117.6462
        )
        expect(@loc.datacite_mapping_box).to eq(expected)
      end

      %i[sw_latitude sw_longitude ne_latitude ne_longitude].each do |coord|
        it "returns nil if #{coord} is missing" do
          @box.send("#{coord}=", nil)
          expect(@loc.datacite_mapping_box).to be_nil
        end
      end
    end
  end
end
