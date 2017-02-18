require 'rails_helper'

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

feature "User creates a dataset and submits it to the repository" do

  background do
	@tenant = ::StashEngine::Tenant.find(tenant_id = "dataone")
	@user = ::StashEngine::User.create(first_name: 'test', last_name: 'user', email: 'testuser.ucop@gmail.com', tenant_id: @tenant.tenant_id)
	# @image_path = File.join(StashDatacite::Engine.root.to_s, 'spec', 'dummy', 'public', 'books.jpeg')
    @image_path = '/bin/ls'
  end

  it "Logged in user fills metadata entry page", js: true do
    visit "http://#{@tenant.full_domain}/stash/auth/developer"
  	within('form') do
  	  fill_in 'Name', with: 'testuser'
  	  fill_in 'Email', with: 'testuser.ucop@gmail.com'
  	  fill_in 'test_domain', with: 'example.edu'
  	  click_button 'Sign In'
  	end

    click_button 'Start New Dataset'

    expect(page).to have_content 'Describe Your Datasets'

    # Data Type
    select 'Multiple Types', from: 'Type of Data'

    # Title
    fill_in 'Title', with: 'Test Dataset - Best practices for creating unique datasets'

    # Author
    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Institutional Affiliation', with: 'UCOP'
    click_link 'Add Author'

    # Abstract
    fill_in 'Abstract', with: "Lorem ipsum dolor sit amet, consectetur"\
    "adipiscing elit. Maecenas posuere quis ligula eu luctus."\
    "Donec laoreet sit amet lacus ut efficitur. Donec mauris erat,"\
    "aliquet eu finibus id, lobortis at ligula. Donec iaculis orci nisl,"\
    "quis vulputate orci efficitur nec. Proin imperdiet in lorem eget sodales."\
    "Etiam blandit eget quam nec tristique. In hac habitasse platea dictumst."\
    "Integer id nunc in purus sagittis dapibus sed ac augue. Aenean eu lobortis turpis."\

    find('summary', text: "Data Description (optional)").click

    #Funding
    # fill_autocomplete 'contributor[contributor_name]', with: 'Royal Norwegian Embassy in London'
    fill_in 'Award Number', with: '21-10-513021'

    # Related work(s)
    select 'is cited by', from: 'related_identifier[relation_type]'
    select 'DOI', from: 'related_identifier[related_identifier_type]'
    fill_in 'Identifier', with: 'gov.noaa.class:AVHRR'
    click_link 'add another related work'

    find('summary', text: "Location Information (optional)").click

    find('#geo_point').click

    #Geolocation Points
    fill_in 'geolocation_point[latitude]', with: '37.801239'
    fill_in 'geolocation_point[longitude]', with: '-122.258301'
    click_button 'Add'

    expect(page).to have_css('div.c-locations__point', text: '37.801239, -122.258301' )

    find('#geo_box').click

    #Geolocation Boxes
    fill_in 'geolocation_box[sw_latitude]', with: '25.8371'
    fill_in 'geolocation_box[sw_longitude]', with: '-106.6460'
    fill_in 'geolocation_box[ne_latitude]', with: '36.5007'
    fill_in 'geolocation_box[ne_longitude]', with: '-93.5083'
    click_button 'Add'

    expect(page).to have_css('div.c-locations__area', text: 'SW 25.8371, -106.646 NE 36.5007, -93.5083')

    click_link 'Proceed to Upload'

    # trying the sauce labs pre-uploaded file
    page.attach_file('upload_upload', @image_path, :visible => false, wait: Capybara.default_max_wait_time)
    page.find('#upload_all', :visible => false).click
    # expect(page).to have_content 'books.jpeg'
    expect(page).to have_content 'ls'

    click_link 'Proceed to Review'

    find('.o-button__submit', visible: false).click
    handle_popups

    expect(page).to have_current_path("/stash/dashboard")
    expect(page).to have_content 'Test Dataset - Best practices for creating unique datasets submitted . There may be a delay for processing before the item is available.'
    sleep 100

    click_link 'Test Dataset - Best practices for creating unique datasets'
    expect(page).to have_content 'The dataset you are trying to view is not available.'
  end
end