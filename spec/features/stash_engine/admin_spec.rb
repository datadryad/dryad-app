RSpec.feature 'Admin', type: :feature do

  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::Ror
  include Mocks::RSolr
  include Mocks::Stripe
  include Mocks::Tenant

  context :administrative_user do

    before(:each) do
      mock_solr!
      mock_stripe!
      mock_ror!
      mock_datacite_and_idgen!
      mock_tenant!
      neuter_curation_callbacks!
      @admin = create(:user, role: 'admin', tenant_id: 'mock_tenant')
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id)
      sign_in(@admin)
    end

    it 'has admin link' do
      visit root_path
      expect(page).to have_link('Admin')
    end

    it "shows a user's version history for a dataset" do
      visit stash_url_helpers.edit_histories_path(resource_id: @resource.id)
      expect(page).to have_text('1 (Submitted)')
    end

    it 'allows editing a dataset', js: true do
      visit stash_url_helpers.admin_user_dashboard_path(@user)
      expect(page).to have_css('button[title="Edit Dataset"]')
      find('button[title="Edit Dataset"]').click
      expect(page).to have_text("You are editing #{@user.name}'s dataset.")
      click_link 'Review and Submit'
      expect(page).to have_css('input#user_comment')
    end

    it 'does not allow editing a dataset from the curation page', js: true do
      visit root_path
      click_link('Admin')
      expect(page).to have_text('Admin Dashboard')

      expect(page).not_to have_css('button[title="Edit Dataset"]')
    end

    it 'redirects to the dataset editing page, and the user is logged in, when requesting an edit link', js: true do
      sign_out
      @identifier.edit_code = Faker::Number.number(digits: 4)
      @identifier.save
      @identifier.resources.first.current_resource_state.update(resource_state: 'in_progress')
      visit "/stash/edit/#{@identifier.identifier}/#{@identifier.edit_code}"
      expect(page).to have_text('Describe Your Dataset')
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
      create(:resource, :submitted, user: new_user, identifier: new_ident)
      visit "/stash/edit/#{new_ident.identifier}/#{new_ident.edit_code}"
      expect(page.current_path).to eq('/stash/sessions/choose_sso')
      expect(page).to have_text('Logout')
    end

    it 'allows a user with a valid edit_code to take ownership of a dataset owned by the system user' do
      new_ident = create(:identifier)
      new_ident.edit_code = Faker::Number.number(digits: 4)
      new_ident.save
      system_user = StashEngine::User.where(id: 0).first || create(:user, id: 0)
      resource = create(:resource, :submitted, user: system_user, identifier: new_ident)
      visit "/stash/edit/#{new_ident.identifier}/#{new_ident.edit_code}"
      expect(page).to have_text('Logout')
      resource.reload
      expect(resource.user_id).to eq(@admin.id)
    end

    it 'forces a non-logged-in user with a valid edit_code to login before take ownership of a dataset owned by the system user' do
      sign_out
      new_ident = create(:identifier)
      new_ident.edit_code = Faker::Number.number(digits: 4)
      new_ident.save
      system_user = create(:user, id: 0)
      create(:resource, :submitted, user: system_user, identifier: new_ident)
      visit "/stash/edit/#{new_ident.identifier}/#{new_ident.edit_code}"
      expect(page.current_path).to eq('/stash/sessions/choose_login')
    end

    context :superuser do

      before(:each) do
        @superuser = create(:user, role: 'superuser', tenant_id: 'dryad')
        sign_in(@superuser, false)
      end

      it 'has admin link', js: true do
        visit root_path
        find('.o-sites__summary', text: 'Admin').click
        expect(page).to have_link('Dataset Curation')
        expect(page).to have_link('Publication Updater')
        expect(page).to have_link('Status Dashboard')
        expect(page).to have_link('Submission Queue')
      end

      it 'allows assigning a curator', js: true do
        @curator = create(:user, role: 'superuser', tenant_id: 'dryad')

        visit root_path
        find('.o-sites__summary', text: 'Admin').click
        find('.o-sites__group-item', text: 'Dataset Curation').click

        expect(page).to have_text('Admin Dashboard')
        expect(page).to have_css('button[title="Update curator"]')
        find('button[title="Update curator"]').click
        find("#resource_current_editor_id option[value='#{@curator.id}']").select_option
        click_button('Submit')

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text(@curator.name.to_s)
        end

      end

      # Skipping this test that fails intermittently, for a feature we're not actually using
      xit 'allows changing user role as a superuser', js: true do
        visit stash_url_helpers.admin_path
        expect(page).to have_link(@user.name)
        within(:css, "form[action=\"#{stash_url_helpers.popup_admin_path(@user.id)}\"]") do
          find('.c-admin-edit-icon').click
        end
        within(:css, 'div.o-admin-dialog') do
          find('#role_admin').set(true)
          find('input[name=commit]').click
        end
        expect(page.find("#user_role_#{@user.id}")).to have_text('Admin')
      end

    end

    context :journal_admin do
      before(:each) do
        @journal = create(:journal)
        @journal_admin = create(:user, tenant_id: 'mock_tenant')
        @journal_role = create(:journal_role, journal: @journal, user: @journal_admin, role: 'admin')
        @journal_admin.reload

        sign_in(@journal_admin, false)
      end

      it 'has admin link' do
        visit root_path
        expect(page).to have_link('Admin')
      end

      it 'only shows datasets from the target journal' do
        ident1 = create(:identifier)
        res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @admin.tenant_id)
        ident2 = create(:identifier)
        res2 = create(:resource, identifier_id: ident2.id, user: @user, tenant_id: @admin.tenant_id)
        StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationISSN', value: @journal.issn)
        StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationName', value: @journal.title)
        ident1.reload

        click_link('Admin')
        expect(page).to have_text('Admin Dashboard')
        expect(page).to have_text(res1.title)
        expect(page).to_not have_text(res2.title)
      end
    end

    context :tenant_curator do

      before(:each) do
        @tenant_curator = create(:user, role: 'tenant_curator', tenant_id: 'mock_tenant')
        sign_in(@tenant_curator, false)
      end

      it 'has admin link' do
        visit root_path
        expect(page).to have_link('Admin')
      end
    end

    it 'allows editing a dataset', js: true do
      visit stash_url_helpers.admin_user_dashboard_path(@user)
      expect(page).to have_css('button[title="Edit Dataset"]')
      find('button[title="Edit Dataset"]').click
      expect(page).to have_text("You are editing #{@user.name}'s dataset.")
      click_link 'Review and Submit'
      expect(page).to have_css('input#user_comment')
    end

    it 'allows adding notes to the curation activity log', js: true do
      visit root_path
      click_link('Admin')
      expect(page).to have_text('Admin Dashboard')

      expect(page).to have_css('button[title="View Activity Log"]')
      find('button[title="View Activity Log"]').click

      expect(page).to have_text('Activity Log for')
      expect(page).to have_text('Add Note')
    end

  end
end
