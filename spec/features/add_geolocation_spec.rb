require 'features_helper'

describe 'add geolocation' do

  before(:each) do
    visit('/')
    first(:link_or_button, 'Login').click
    first(:link_or_button, 'Start New Dataset').click

    location_divider = find('summary', text: 'Location Information (optional)')
    location_divider.click
  end

  describe 'points' do
    it 'adds by lat/long' do
      latitude = '37.8086'
      longitude = '-122.2674'

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
end
