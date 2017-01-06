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
      fill_in 'test_domain', with: 'testuser@example.edu'
      click_button 'Sign In'
    end
    if page.has_content?('My Datasets: Getting Started') == true
      click_button 'Start New Dataset'
    else
      click_button 'Resume'
    end
    sleep 5
    expect(page).to have_content 'Describe Your Datasets'

    click_link 'Proceed to Upload'
    script = "$('#upload_upload').css({opacity: 100, display: 'block'});"
    page.driver.browser.execute_script(script)
    # ('input[id="upload_upload"]').set(@file_path)
    page.find('#upload_all', visible: false).click

    sleep 5
    expect(page).to have_content 'UC3-Dash.pdf'
    # page.evaluate_script("window.location.reload()")
    # file_field = page.find('input[id="upload_upload"]', visible: false)
    # file_field.set(@image_path)
    # click_button('Upload')
    # sleep 5

    # click_link 'Proceed to Review'

  end
end