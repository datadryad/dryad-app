require 'rails_helper'

# RSpec.configure do |config|
#   config.include WaitForAjax, type: :feature
# end

feature "User lands on Uploads page and navigates through it" do

  background do
    @tenant = ::StashEngine::Tenant.find(tenant_id = "dataone")
    @user = ::StashEngine::User.create(first_name: 'test', last_name: 'user', email: 'testuser.ucop@gmail.com', tenant_id: @tenant.tenant_id)
    @image_path = File.join(Rails.root, '/spec/support/books.jpeg')
    @file_path = File.join(Rails.root, '/spec/support/UC3-Dash.pdf')
  end

  it "Logged in user fills metadata entry page", js: true do
    visit "localhost:3000/stash"
    visit "http://#{@tenant.full_domain}/stash/auth/developer"

    within('form') do
      fill_in 'Name', with: 'testuser'
      fill_in 'Email', with: 'testuser.ucop@gmail.com'
      fill_in 'test_domain', with: 'testuser@ucop.edu'
      click_button 'Sign In'
    end
    if page.has_content?('My Datasets: Getting Started') == true
      click_button 'Start New Dataset'
    else
      click_button 'Resume'
    end
    expect(page).to have_content 'Describe Your Datasets'

    click_link 'Proceed to Upload'

    file_field = page.find('input[id="upload_upload"]', visible: false)
    file_field.set(@file_path)
    find('#upload_all').click
    sleep 3
    page.evaluate_script("window.location.reload()")
    file_field = page.find('input[id="upload_upload"]', visible: false)
    file_field.set(@image_path)
    click_button('Upload')
    sleep 3

    click_link 'Proceed to Review'

  end
end