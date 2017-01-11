require 'rails_helper'

def wait_for_ajax
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until finished_all_ajax_requests?
  end
end

def finished_all_ajax_requests?
  page.evaluate_script('jQuery.active').zero?
end

def handle_popups
  if page.driver.class == Capybara::Selenium::Driver
    page.driver.browser.switch_to.alert.accept
  elsif page.driver.class == Capybara::Webkit::Driver
    sleep 1 # prevent test from failing by waiting for popup
    page.driver.browser.accept_js_confirms
  else
    raise "Unsupported driver"
  end
end

feature "User updates and submits a published dataset" do

  background do
    @tenant = ::StashEngine::Tenant.find(tenant_id = "dataone")
    @user = ::StashEngine::User.create(first_name: 'test', last_name: 'user', email: 'testuser.ucop@gmail.com', tenant_id: @tenant.tenant_id)
    @file_path = File.join(Rails.root, '/public/UC3-Dash.pdf')
  end

  it "Logged in user fills metadata entry page", js: true do
    visit "localhost:3000/stash"
    visit "http://#{@tenant.full_domain}/stash/auth/developer"

    within('form') do
      fill_in 'Name', with: 'testuser'
      fill_in 'Email', with: 'testuser.ucop@gmail.com'
      fill_in 'test_domain', with: 'testuser@example.edu'
      click_button 'Sign In'
    end

    click_button 'Start New Dataset'
    wait_for_ajax
    expect(page).to have_content 'Describe Your Datasets'

    #Data Type
    select 'Multiple Types', from: 'Type of Data'

    #Title
    fill_in 'Title', with: 'Test Dataset - Best practices for creating unique datasets'

    #Author
    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
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

    #Funding
    # fill_autocomplete('contributor_name', with: 'Royal Norwegian Embassy in London')
    # ## This is an example of something that should be on your screen after you make the selection
    # page.should have_content("Royal Norwegian Embassy in London")
    fill_in 'Award Number', with: '21-10-513021'

    #Related work(s)
    select 'is cited by', from: 'related_identifier[relation_type]'
    select 'DOI', from: 'related_identifier[related_identifier_type]'
    fill_in 'Identifier', with: 'gov.noaa.class:AVHRR'
    click_link 'add another related work'

    click_link 'Review and Submit'
    wait_for_ajax
    find('.o-button__submit', visible: false).click
    handle_popups

    expect(page).to have_current_path("/stash/dashboard")
    sleep 10
    click_button 'Update'
    wait_for_ajax

    expect(page).to have_content 'Describe Your Datasets'

    find('summary', text: "Location Information (optional)").click

    find('#geo_point').click

    #Geolocation Points
    fill_in 'geolocation_point[latitude]', with: '37.801239'
    fill_in 'geolocation_point[longitude]', with: '-122.258301'
    click_button 'Add'
    wait_for_ajax
    expect(page).to have_css('div.c-locations__point', text: '37.801239, -122.258301' )

    find('#geo_box').click

    #Geolocation Boxes
    fill_in 'geolocation_box[sw_latitude]', with: '25.8371'
    fill_in 'geolocation_box[sw_longitude]', with: '-106.6460'
    fill_in 'geolocation_box[ne_latitude]', with: '36.5007'
    fill_in 'geolocation_box[ne_longitude]', with: '-93.5083'
    click_button 'Add'
    wait_for_ajax
    expect(page).to have_css('div.c-locations__area', text: 'SW 25.8371, -106.646 NE 36.5007, -93.5083')

    click_link 'Proceed to Upload'
    page.find('input[id="upload_upload"]', visible: false).set(@file_path)
    page.find('#upload_all', visible: false).click

    wait_for_ajax
    page.evaluate_script("window.location.reload()")
    expect(page).to have_content 'UC3-Dash.pdf'

    click_link 'Proceed to Review'
    wait_for_ajax
    find('.o-button__submit', visible: false).click
    handle_popups

    expect(page).to have_current_path("/stash/dashboard")
    expect(page).to have_content 'Test Dataset - Best practices for creating unique datasets submitted . There may be a delay for processing before the item is available.'
    sleep 15

    click_link 'Test Dataset - Best practices for creating unique datasets'
    expect(page).to have_content 'The dataset you are trying to view is not available.'
  end
end