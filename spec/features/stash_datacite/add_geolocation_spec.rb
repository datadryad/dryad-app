require 'rails_helper'
require 'pry'

RSpec.feature 'Add Geolocation to Dataset', type: :feature do

  include DatasetHelper

  context 'dataset', js: true do
    before(:each) do
      start_new_dataset
      location_divider = find('summary', text: 'Location Information (optional)')
      location_divider.click
      wait_for_ajax!
    end

    context 'points' do

      it 'adds by lat/long' do
        latitude = Faker::Geolocation.lat
        longitude = Faker::Geolocation.lng

        point_latitude = find_blank_field_id('geolocation_point[latitude]')
        fill_in point_latitude, with: latitude

        point_longitude = find_blank_field_id('geolocation_point[longitude]')
        fill_in point_longitude, with: longitude

        add_geo_point_button = first(:link_or_button, 'add_geo_point')
        add_geo_point_button.click

        wait_for_ajax!

        locations = page.find('div .c-locations')
        expect(locations).to have_content(/#{latitude},\s+#{longitude}/)

        new_point = StashDatacite::GeolocationPoint.from_resource_id(current_resource_id).first
        expect(new_point).not_to be_nil
        expect(new_point.latitude).to eq(latitude.to_f)
        expect(new_point.longitude).to eq(longitude.to_f)
      end

    end

    context 'boxes' do

      it 'adds by lat/long' do
        bbox_button = first(:link_or_button, 'Bounding Box')
        bbox_button.click

        s_latitude = Faker::Geolocation.lat
        w_longitude = Faker::Geolocation.lng

        n_latitude = s_latitude + 0.5
        e_longitude = w_longitude - 0.10

        sw_latitude = find_blank_field_id('geolocation_box[sw_latitude]')
        fill_in sw_latitude, with: s_latitude

        sw_longitude = find_blank_field_id('geolocation_box[sw_longitude]')
        fill_in sw_longitude, with: w_longitude

        ne_latitude = find_blank_field_id('geolocation_box[ne_latitude]')
        fill_in ne_latitude, with: n_latitude

        ne_longitude = find_blank_field_id('geolocation_box[ne_longitude]')
        fill_in ne_longitude, with: e_longitude

        add_geo_box_button = first(:link_or_button, 'add_geo_box')
        add_geo_box_button.click

        wait_for_ajax!

        locations = page.find('div .c-locations')
        expect(locations).to have_content(/SW\s+#{s_latitude},\s+#{w_longitude}/)
        expect(locations).to have_content(/NE\s+#{n_latitude},\s+#{e_longitude}/)

        new_box = StashDatacite::GeolocationBox.from_resource_id(current_resource_id).first
        expect(new_box).not_to be_nil
        expect(new_box.sw_latitude).to eq(s_latitude.to_f)
        expect(new_box.sw_longitude).to eq(w_longitude.to_f)
        expect(new_box.ne_latitude).to eq(n_latitude.to_f)
        expect(new_box.ne_longitude).to eq(e_longitude.to_f)
      end

    end

    context 'google_geocoding' do

      it 'adds a place by name' do
        item = find('div.leaflet-control-geosearch input.glass')
        item.set('Oakland, CA, USA')
        item.send_keys(:return)
        wait_for_ajax!
        # this triggers the leaflet map move and display but the 'geosearch/showlocation' event doesn't always trigger by geosearch library
        # binding.pry
        if APP_CONFIG.google_maps_api_key.blank? # hard to test this without exposing API key in public repo
          expect(true).to eq(true)
        else
          expect(find('div.geolocation_places').has_content?('Oakland, CA, USA')).to eq(true)
        end
      end

    end

  end

end
