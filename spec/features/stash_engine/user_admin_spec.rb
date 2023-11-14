require 'pry-remote'

RSpec.feature 'UserAdmin', type: :feature do

  include DatasetHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::Tenant
  include Mocks::DataFile

  context :user_admin do

    before(:each) do
      mock_salesforce!
      mock_solr!
      mock_stripe!
      mock_datacite_gen!
      mock_tenant!
      neuter_curation_callbacks!
      @user = create(:user, tenant_id: 'mock_tenant')
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @user.tenant_id)
      @superuser = create(:user, role: 'superuser', tenant_id: 'dryad')
      sign_in(@superuser, false)
    end

    it 'allows filtering by institution', js: true do
      expect do
        @user1 = create(:user, tenant_id: 'dataone')
        @user2 = create(:user, tenant_id: 'ucop')
      end.to change(StashEngine::User, :count).by(2)
      visit stash_url_helpers.user_admin_path
      select 'DataONE', from: 'tenant_id'
      click_on 'Search'
      expect(page).to have_link(@user1.name)
      expect(page).not_to have_link(@user2.name)
    end

    it 'allows changing user email as a superuser', js: true do
      expect { @user = create(:user) }.to change(StashEngine::User, :count).by(1)
      visit stash_url_helpers.user_admin_path
      expect(page).to have_link(@user.name)
      within(:css, "form[action=\"#{stash_url_helpers.user_email_popup_path(@user.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#email').set('new-email@example.org')
        find('input[name=commit]').click
      end
      expect(page.find("#user_email_#{@user.id}")).to have_text('new-email@example.org')
      user_changed = StashEngine::User.find(@user.id)
      expect(user_changed.email).to eq('new-email@example.org')
    end

    it 'allows changing user role as a superuser', js: true do
      expect { @user = create(:user) }.to change(StashEngine::User, :count).by(1)
      visit stash_url_helpers.user_admin_path
      expect(page).to have_link(@user.name)
      within(:css, "form[action=\"#{stash_url_helpers.user_role_popup_path(@user.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#role_admin').set(true)
        find('input[name=commit]').click
      end
      expect(page.find("#user_role_#{@user.id}")).to have_text('Admin')
      user_changed = StashEngine::User.find(@user.id)
      expect(user_changed.role).to eq('admin')
    end

    it 'allows changing user tenant as a superuser', js: true do
      expect { @user = create(:user) }.to change(StashEngine::User, :count).by(1)
      visit stash_url_helpers.user_admin_path
      expect(page).to have_link(@user.name)
      within(:css, "form[action=\"#{stash_url_helpers.user_tenant_popup_path(@user.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#tenant').click
        find("option[value='localhost']").select_option
        find('input[name=commit]').click
      end

      # NOTE: Although this tests the process of changing a tenant, it doesn't actually test the result,
      # since the Mock Tenant makes everything look like the same tenant. Doing this "right" would require
      # even more contortions than the ones in `tenant_spec.rb`, and it's not really worthwhile.
    end

    it 'allows merging users as a superuser', js: true do
      user = create(:user)
      user2 = create(:user)
      user_id = user.id
      user2_id = user2.id
      user_after = nil

      # Set some fields nil so we can test that the merge result contains the non-nil fields
      user.update(email: nil)
      user2.update(orcid: nil)
      target_email = user2.email
      target_orcid = user.orcid

      visit stash_url_helpers.user_admin_path
      expect(page).to have_link(user.name)
      expect(page).to have_link(user2.name)

      # Click each select box
      find("#user_ids_selections_#{user.id}").click
      find("#user_ids_selections_#{user2.id}").click

      # Do the merge dialog
      click_button('Merge selected')
      expect(page).to have_text('Merge users')
      click_button('Merge')
      expect(page).to have_text('Manage users')

      sleep 1 # since it takes some time for async action to reflect in db
      if StashEngine::User.all.map(&:id).include?(user_id)
        expect(StashEngine::User.all.map(&:id)).not_to include(user2_id)
        user_after = StashEngine::User.find(user_id)
      else
        expect(StashEngine::User.all.map(&:id)).to include(user2_id)
        user_after = StashEngine::User.find(user2_id)
      end

      # user should be updated with new values
      expect(user_after.email).to eq(target_email)
      expect(user_after.orcid).to eq(target_orcid)
    end
  end
end
