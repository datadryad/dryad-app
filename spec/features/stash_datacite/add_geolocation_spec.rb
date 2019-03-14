require 'rails_helper'
require 'pry'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'Add Geolocation to Dataset', type: :feature do

  include DatasetHelper

  before(:all) do
    # Start Solr - shutdown is handled globally when all tests have finished
    SolrInstance.instance
  end

  context 'dataset', js: true do
    before(:each) do
      @n_lat = 37.8044
      @e_lng = -122.2711
      @s_lat = 37.7044
      @w_lng = -122.3711

      sign_in
      start_new_dataset
      @resource_id = page.first('#resource_id', visible: false).value
      find('#location_opener').click
    end

    context 'points' do

      it 'adds by lat/long' do
        fill_in 'geolocation_point[latitude]', with: @n_lat
        fill_in 'geolocation_point[longitude]', with: @e_lng
        click_button 'add_geo_point'
        # wait_for_ajax(15)

        expect(page.find('div .c-locations')).to have_content(/#{@n_lat},\s+#{@e_lng}/, wait: 15)

        new_point = StashDatacite::GeolocationPoint.from_resource_id(@resource_id).first
        expect(new_point).not_to be_nil
        expect(new_point.latitude).to eq(@n_lat.to_f)
        expect(new_point.longitude).to eq(@e_lng.to_f)
      end

    end

    context 'boxes' do

      it 'adds by lat/long' do
        click_button 'Bounding Box'
        fill_in 'geolocation_box[sw_latitude]', with: @s_lat
        fill_in 'geolocation_box[sw_longitude]', with: @w_lng
        fill_in 'geolocation_box[ne_latitude]', with: @n_lat
        fill_in 'geolocation_box[ne_longitude]', with: @e_lng
        click_button 'add_geo_box'
        # wait_for_ajax(15)

        locations = page.find('div .c-locations')
        expect(locations).to have_content(/SW\s+#{@s_lat},\s+#{@w_lng}/, wait: 15)
        expect(locations).to have_content(/NE\s+#{@n_lat},\s+#{@e_lng}/)

        new_box = StashDatacite::GeolocationBox.from_resource_id(@resource_id).first
        expect(new_box).not_to be_nil
        expect(new_box.sw_latitude).to eq(@s_lat.to_f)
        expect(new_box.sw_longitude).to eq(@w_lng.to_f)
        expect(new_box.ne_latitude).to eq(@n_lat.to_f)
        expect(new_box.ne_longitude).to eq(@e_lng.to_f)
      end

    end

    context 'google_geocoding' do

      it 'adds a place by name' do
        item = find('div.leaflet-control-geosearch input.glass')
        item.set('Oakland, CA, USA')
        item.send_keys(:return)
        # wait_for_ajax(15)

        # this triggers the leaflet map move and display but the 'geosearch/showlocation' event doesn't always trigger by geosearch library
        # binding.pry
        if APP_CONFIG.google_maps_api_key.blank? # hard to test this without exposing API key in public repo
          expect(true).to eq(true)
        else
          expect(find('div.geolocation_places').has_content?('Oakland, CA, USA', wait: 15)).to eq(true)
        end
      end

    end

  end

end
# rubocop:enable Metrics/BlockLength
