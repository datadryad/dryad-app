require 'rails_helper'
require 'database_cleaner'
# RSpec.configure do |config|
#   config.include FeatureHelper, :type => :feature
# end

feature "User lands on metadata entry page and navigates through it" do

  background do
  @tenant = ::StashEngine::Tenant.find(tenant_id = "dataone")
  @user = ::StashEngine::User.create(first_name: 'test', last_name: 'user', email: 'testuser.ucop@gmail.com', tenant_id: @tenant.tenant_id)
  @image_path = File.join(Rails.root, '/spec/support/books.jpeg')
  end

  it "Logged in user fills metadata entry page", js: true do
  # visit "https://oneshare2-dev.cdlib.org/stash/auth/developer"
    visit "localhost:3000/stash"
    visit "http://#{@tenant.full_domain}/stash/auth/developer"
  within('form') do
    fill_in 'Name', with: 'testuser'
    fill_in 'Email', with: 'testuser.ucop@gmail.com'
    fill_in 'test_domain', with: 'example.edu'
    click_button 'Sign In'
  end
  sleep 3
  click_button 'Update'
  sleep 3
  expect(page).to have_content 'Describe Your Datasets'

  #Data Type
  select 'Spreadsheet', from: 'Type of Data'

  #Title
  fill_in 'Title', with: 'Test Dataset - Updating practices for creating unique datasets'

  #Author
  fill_in 'First Name', with: 'Test 2'
  fill_in 'Last Name', with: 'User 2'
  fill_in 'Institutional Affiliation', with: 'UCOP'
  click_link 'Add Author'

  #Abstract
  fill_in 'Abstract', with: "Lorem ipsum dolor sit amet, consectetur"\
  "adipiscing elit. Maecenas posuere quis ligula eu luctus."\
  "Donec laoreet sit amet lacus ut efficitur. Donec mauris erat,"\
  "aliquet eu finibus id, lobortis at ligula. Donec iaculis orci nisl,"\
  "quis vulputate orci efficitur nec. Proin imperdiet in lorem eget sodales."\
  "Etiam blandit eget quam nec tristique. In hac habitasse platea dictumst."\
  "Integer id nunc in purus sagittis dapibus sed ac augue. Aenean eu lobortis turpis."\

  find('summary', text: "Data Description (optional)").click

  #Related work(s)
  select 'cites', from: 'related_identifier[relation_type]'
  select 'DOI', from: 'related_identifier[related_identifier_type]'
  fill_in 'Identifier', with: 'gov.noaa.class:AVHRR'
  click_link 'add another related work'

  find('summary', text: "Location Information (optional)").click

  find('#geo_point').click

  #Geolocation Points
  fill_in 'geolocation_point[latitude]', with: '25.8371'
  fill_in 'geolocation_point[longitude]', with: '-106.6460'
  click_button 'Add'
  sleep 5
  expect(page).to have_css('div.c-locations__point', text: '25.8371, -106.6460' )

  find('#geo_box').click

  click_link 'Proceed to Upload'

  file_field = page.find('input[id="upload_upload"]', visible: false)
  file_field.set(@image_path)
  find('#upload_all').click
  sleep 5

  click_link 'Proceed to Review'
  sleep 5
  click_button 'Submit'

  page.driver.browser.alert.accept

  sleep 5

  end
end