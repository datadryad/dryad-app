require 'rails_helper'
feature 'User Creates a new Dataset and submits' do

  background do
    @tenant = StashEngine::Tenant.find(tenant_id = "dataone")
    @user = StashEngine::User.create(first_name: 'test', last_name: 'user', email: 'testuser.ucop@gmail.com', tenant_id: @tenant.tenant_id)
  end

  scenario "Create a new Dataset and enter metadata", js: true do
    visit "localhost:3000/stash"
    if page.has_content?('My Datasets: Getting Started') == true
      click_button 'Start New Dataset'
    else
      click_button 'Resume'
    end
    expect(page).to have_content 'Describe Your Datasets'
    click_button 'Logout'
    current_path.should == "/stash/"
  end
end