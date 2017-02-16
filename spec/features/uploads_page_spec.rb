require 'rails_helper'

feature "User lands on Uploads page and navigates through it" do

  background do
    @tenant = ::StashEngine::Tenant.find(tenant_id = "dataone")
    @user = ::StashEngine::User.create(first_name: 'test', last_name: 'user', email: 'testuser.ucop@gmail.com', tenant_id: @tenant.tenant_id)
    @file_path = File.join(StashDatacite::Engine.root.to_s, 'spec', 'dummy', 'public', 'UC3-Dash.pdf')
    @image_path = File.join(StashDatacite::Engine.root.to_s, 'spec', 'dummy', 'public', 'books.jpeg')
    @large_file_path = File.join(StashDatacite::Engine.root.to_s, 'spec', 'dummy', 'public', 'test_100mb_file.pdf')
  end

  it "Logged in user fills metadata entry page", js: true do
    visit "http://#{@tenant.full_domain}/stash/auth/developer"

    within('form') do
      fill_in 'Name', with: 'testuser'
      fill_in 'Email', with: 'testuser.ucop@gmail.com'
      fill_in 'test_domain', with: 'testuser@example.edu'
      click_button 'Sign In'
    end

    click_button 'Start New Dataset'

    expect(page).to have_content 'Describe Your Datasets'

    #Data Type
    select 'Multiple Types', from: 'Type of Data'

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

    click_link 'Proceed to Upload'
    page.attach_file('upload_upload', @image_path, :visible => false, wait: Capybara.default_max_wait_time)
    page.find('#upload_all', :visible => false).click
    sleep 20
    expect(page).to have_content 'books.jpeg'

    # attach_file("Choose Files", @image_path)
    # page.find('#upload_all').click
    # sleep 5
    # expect(page).to have_content 'books.jpeg'

    # page.find('input[id="upload_upload"]', visible: false).set(@large_file_path)
    # page.find('#upload_all').click
    # sleep 30
    # expect(page).to have_content 'test_100mb_file.pdf'
    click_link 'Proceed to Review'

    expect(page).to have_content 'Finalize Submission'
    expect(page).to have_content 'Test Dataset - Updating practices for creating unique datasets'
  end
end