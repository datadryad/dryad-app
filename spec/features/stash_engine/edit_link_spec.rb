RSpec.feature 'EditLink', type: :feature do

  include DatasetHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::DataFile
  include Mocks::Aws

  context :return_url do
    before(:each) do
      mock_solr!
      mock_salesforce!
      mock_file_content!
      mock_aws!
      allow_any_instance_of(StashEngine::DataFile).to receive(:uploaded).and_return(true)
    end

    it 'opens a page with an edit link and redirects when complete', js: true do
      content = Faker::Lorem.paragraph
      @identifier = create(:identifier, edit_code: Faker::Number.number(digits: 5), import_info: 'other')
      @res = create(:resource, tenant_id: 'email_auth', identifier: @identifier, user: create(:user, tenant_id: 'email_auth'))
      create(:data_file, resource: @res)
      create(:description, description_type: 'technicalinfo', resource: @res, description: content)
      @res.reload
      sign_out
      # Edit link for the above dataset, including a returnURL that should redirect to a documentation page
      visit "/edit/#{@identifier.identifier}/#{@identifier.edit_code}?returnURL=%2Fhelp"
      expect(page).to have_text('You are editing this dataset on behalf of')
      navigate_to_metadata
      click_button 'Subjects'
      fill_in_keywords
      click_button 'Compliance'
      fill_in_validation
      navigate_to_review
      submit_form
      expect(page.current_path).to eq('/help')
    end
  end

  context :edit_codes do
    before(:each) do
      mock_salesforce!
      mock_solr!
      mock_stripe!
      mock_datacite_gen!
      neuter_curation_callbacks!
      @admin = create(:user)
      create(:role, user: @admin, role: 'admin', role_object: @admin.tenant)
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id)
      sign_in(@admin)
    end

    it "shows a user's version history for a dataset" do
      visit stash_url_helpers.edit_histories_path(resource_id: @resource.id)
      expect(page).to have_text('1 (Submitted)')
    end

    it 'redirects to the dataset editing page, as the submitter, when the user is not logged in and using an edit link', js: true do
      sign_out
      @identifier.edit_code = Faker::Number.number(digits: 4)
      @identifier.save
      @identifier.resources.first.current_resource_state.update(resource_state: 'in_progress')
      visit "/edit/#{@identifier.identifier}/#{@identifier.edit_code}"
      expect(page).to have_text('Dataset submission')
      expect(page).to have_text('User settings')
      expect(page).to have_text('You are editing this dataset on behalf of')
    end

    it 'rejects an attempt to edit the dataset with an invalid edit_code', js: true do
      @identifier.edit_code = Faker::Number.number(digits: 4)
      @identifier.save
      @identifier.resources.first.current_resource_state.update(resource_state: 'in_progress')
      visit "/edit/#{@identifier.identifier}/bad-code"
      expect(page).to have_text('being edited by another user')
    end

    it 'does not redirect to the dataset editing page when requesting an edit link for a different tenant without an edit_code', js: true do
      @resource.update(tenant_id: 'dryad')
      @resource.reload
      visit stash_url_helpers.dashboard_path
      visit "/edit/#{@identifier.identifier}"
      expect(page).to have_text('does not exist')
    end

    it 'redirects to the tenant selection page when using an edit_code and target user does not have a tenant' do
      sign_out
      new_ident = create(:identifier)
      new_ident.edit_code = Faker::Number.number(digits: 4)
      new_ident.save
      new_user = create(:user, tenant_id: nil)
      expect { create(:resource, :submitted, user: new_user, identifier: new_ident) }.to change(StashEngine::Resource, :count).by(1)
      visit "/edit/#{new_ident.identifier}/#{new_ident.edit_code}"
      expect(page).to have_text('User settings')
    end

    it 'allows a user with a valid edit_code to take ownership of a dataset owned by the system user' do
      Timecop.travel(Time.now.utc - 1.minute)
      new_ident = create(:identifier)
      new_ident.edit_code = Faker::Number.number(digits: 4)
      new_ident.save
      system_user = StashEngine::User.where(id: 0).first || create(:user, id: 0)
      expect { @resource = create(:resource, :submitted, user: system_user, identifier: new_ident) }.to change(StashEngine::Resource, :count).by(1)
      Timecop.return
      visit "/edit/#{new_ident.identifier}/#{new_ident.edit_code}"
      expect(page).to have_text('User settings')
      @resource.reload
      expect(@resource.submitter.id).to eq(@admin.id)
    end

    it 'forces a non-logged-in user with a valid edit_code to login before take ownership of a dataset owned by the system user' do
      sign_out
      new_ident = create(:identifier)
      new_ident.edit_code = Faker::Number.number(digits: 4)
      new_ident.save
      expect { create(:resource, :submitted, user_id: 0, identifier: new_ident) }.to change(StashEngine::Resource, :count).by(1)
      visit "/edit/#{new_ident.identifier}/#{new_ident.edit_code}"
      expect(page.current_path).to eq('/sessions/choose_login')
    end
  end
end
