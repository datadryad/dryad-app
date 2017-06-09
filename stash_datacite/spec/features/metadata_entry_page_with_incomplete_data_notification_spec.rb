require 'rails_helper'

feature 'User lands on metadata entry page and navigates through it' do
  background do
    @tenant = ::StashEngine::Tenant.find('dataone')
    @user = ::StashEngine::User.create(first_name: 'test', last_name: 'user', email: 'testuser.ucop@gmail.com', tenant_id: @tenant.tenant_id)
  end

  it 'Logged in user fills metadata entry page', js: true do
    visit "http://#{@tenant.full_domain}/stash/auth/developer"

    within('form') do
      fill_in 'Name', with: 'testuser'
      fill_in 'Email', with: 'testuser.ucop@gmail.com'
      fill_in 'test_domain', with: 'testuser@example.edu'
      click_button 'Sign In'
    end

    click_button 'Start New Dataset'

    expect(page).to have_content 'Describe Your Datasets'

    # Data Type
    select 'Image', from: 'Type of Data'

    # #Title
    fill_in 'Title', with: 'Test Dataset - In Identification Information Section'

    # #Author
    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    click_link 'Add Author'

    # Abstract
    fill_in 'Abstract', with: 'Lorem ipsum dolor sit amet, consectetur'\
    'adipiscing elit. Maecenas posuere quis ligula eu luctus.'\
    'Donec laoreet sit amet lacus ut efficitur. Donec mauris erat,'\
    'aliquet eu finibus id, lobortis at ligula. Donec iaculis orci nisl,'\
    'quis vulputate orci efficitur nec. Proin imperdiet in lorem eget sodales.'\
    'Etiam blandit eget quam nec tristique. In hac habitasse platea dictumst.'\
    'Integer id nunc in purus sagittis dapibus sed ac augue. Aenean eu lobortis turpis.'\

    find('summary', text: 'Data Description (optional)').click

    # #Keywords
    fill_in 'Keywords', with: 'testing all, possible options'

    click_link 'Review and Submit'

    expect(page).to have_content 'Finalize Submission'

    expect(page).to have_content 'You must edit the description to include the following before you can submit your dataset: Author Affiliation'
  end
end
