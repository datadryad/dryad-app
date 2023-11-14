require 'pry-remote'

RSpec.feature 'Admin', type: :feature do

  include DatasetHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::Tenant
  include Mocks::DataFile

  context :tenant_admin do

    before(:each) do
      mock_salesforce!
      mock_solr!
      mock_stripe!
      mock_datacite_gen!
      mock_tenant!
      neuter_curation_callbacks!
      @admin = create(:user, role: 'admin', tenant_id: 'mock_tenant')
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id)
      sign_in(@admin)
    end

    it "shows a user's version history for a dataset" do
      visit stash_url_helpers.edit_histories_path(resource_id: @resource.id)
      expect(page).to have_text('1 (Submitted)')
    end

    it 'redirects to the dataset editing page, and the user is logged in, when requesting an edit link', js: true do
      sign_out
      @identifier.edit_code = Faker::Number.number(digits: 4)
      @identifier.save
      @identifier.resources.first.current_resource_state.update(resource_state: 'in_progress')
      visit "/stash/edit/#{@identifier.identifier}/#{@identifier.edit_code}"
      expect(page).to have_text('Describe your dataset')
      expect(page).to have_text('Logout')
    end

    it 'rejects an attempt to edit the dataset with an invalid edit_code', js: true do
      @identifier.edit_code = Faker::Number.number(digits: 4)
      @identifier.save
      @identifier.resources.first.current_resource_state.update(resource_state: 'in_progress')
      visit "/stash/edit/#{@identifier.identifier}/bad-code"
      expect(page).to have_text('do not have permission to modify')
    end

    it 'does not redirect to the dataset editing page when requesting an edit link for a different tenant without an edit_code', js: true do
      @resource.tenant_id = 'dryad'
      @resource.save
      sleep 1
      @resource.reload
      sleep 1
      visit stash_url_helpers.dashboard_path
      visit "/stash/edit/#{@identifier.identifier}"
      expect(page).to have_text('does not exist')
    end

    it 'redirects to the tenant selection page when using an edit_code and target user does not have a tenant' do
      sign_out
      new_ident = create(:identifier)
      new_ident.edit_code = Faker::Number.number(digits: 4)
      new_ident.save
      new_user = create(:user, tenant_id: nil)
      expect { create(:resource, :submitted, user: new_user, identifier: new_ident) }.to change(StashEngine::Resource, :count).by(1)
      visit "/stash/edit/#{new_ident.identifier}/#{new_ident.edit_code}"
      expect(page.current_path).to eq('/stash/sessions/choose_sso')
      expect(page).to have_text('Logout')
    end

    it 'allows a user with a valid edit_code to take ownership of a dataset owned by the system user' do
      new_ident = create(:identifier)
      new_ident.edit_code = Faker::Number.number(digits: 4)
      new_ident.save
      system_user = StashEngine::User.where(id: 0).first || create(:user, id: 0)
      expect { @resource = create(:resource, :submitted, user: system_user, identifier: new_ident) }.to change(StashEngine::Resource, :count).by(1)
      visit "/stash/edit/#{new_ident.identifier}/#{new_ident.edit_code}"
      expect(page).to have_text('Logout')
      @resource.reload
      expect(@resource.user_id).to eq(@admin.id)
    end

    it 'forces a non-logged-in user with a valid edit_code to login before take ownership of a dataset owned by the system user' do
      sign_out
      new_ident = create(:identifier)
      new_ident.edit_code = Faker::Number.number(digits: 4)
      new_ident.save
      system_user = create(:user, id: 0)
      expect { create(:resource, :submitted, user: system_user, identifier: new_ident) }.to change(StashEngine::Resource, :count).by(1)
      visit "/stash/edit/#{new_ident.identifier}/#{new_ident.edit_code}"
      expect(page.current_path).to eq('/stash/sessions/choose_login')
    end
  end
end
