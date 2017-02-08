require 'rails_helper'

def wait_for_ajax
  Capybara.default_max_wait_time = 500
end

# def finished_all_ajax_requests?
#     page.evaluate_script("jQuery.active") == 0
# end

feature "User lands on metadata entry page and navigates through it" do

  background do
    @tenant = ::StashEngine::Tenant.find(tenant_id = "dataone")
    @user = ::StashEngine::User.create(first_name: 'test', last_name: 'user', email: 'testuser.ucop@gmail.com', tenant_id: @tenant.tenant_id)
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

    wait_for_ajax
    expect(page).to have_content 'Describe Your Datasets'

    #Data Type
    select 'Image', from: 'Type of Data'

    # #Title
    fill_in 'Title', with: 'Test Dataset - In Identification Information Section'

    # #Author
    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    click_link 'Add Author'

    find('summary', text: "Data Description (optional)").click

    # #Keywords
    fill_in 'Keywords', with: 'testing all, possible options'

    click_link 'Review and Submit'
    wait_for_ajax

    expect(page).to have_content 'Finalize Submission'
    sleep 3
    expect(page).to have_content 'You must edit the description to include the following before you can submit your dataset: Abstract Author Affiliation'
  end
end