# coding: utf-8
require 'pry-remote'

RSpec.feature 'Admin', type: :feature do

  include DatasetHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::Tenant

  context :administrative_user do

    before(:each) do
      mock_salesforce!
      mock_solr!
      mock_stripe!
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
      section = find('.c-header_nav-button', text: 'Datasets').text
      expect(section).to eq('Datasets')
    end

    it "shows a user's version history for a dataset" do
      visit stash_url_helpers.edit_histories_path(resource_id: @resource.id)
      expect(page).to have_text('1 (Submitted)')
    end

    it 'does not allow editing a dataset from the curation page', js: true do
      visit root_path
      find('.c-header_nav-button', text: 'Datasets').click
      page.has_link?('.c-header__nav-submenu')
      click_link('Admin dashboard')
      expect(page).to have_text('Admin dashboard')
      expect(page).not_to have_css('button[title="Edit Dataset"]')
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

    it 'allows adding notes to the curation activity log', js: true do
      visit root_path
      find('.c-header_nav-button', text: 'Datasets').click
      page.has_link?('Admin dashboard')
      click_link('Admin dashboard')

      expect(page).to have_text('Admin dashboard')

      expect(page).to have_css('button[title="View Activity Log"]')
      find('button[title="View Activity Log"]').click

      expect(page).to have_text('Activity log for')
      expect(page).to have_text('Add note')
    end

    context :dataset_admin do

      before(:each) do
        mock_salesforce!
        @superuser = create(:user, role: 'superuser', tenant_id: 'dryad')
        sign_in(@superuser, false)
      end

      it 'has admin link', js: true do
        visit root_path
        find('.c-header_nav-button', text: 'Datasets').click
        page.has_link?('Dataset curation')
        expect(page).to have_link('Dataset curation')
        expect(page).to have_link('Publication updater')
        expect(page).to have_link('Status dashboard')
        expect(page).to have_link('Submission queue')
      end

      it 'allows editing a dataset', js: true do
        @user = create(:user, tenant_id: @admin.tenant_id)
        @identifier = create(:identifier)
        expect { @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id) }
          .to change(StashEngine::Resource, :count).by(1)
        expect { @resource.subjects << [create(:subject), create(:subject), create(:subject)] }
          .to change(StashDatacite::Subject, :count).by(3)
        visit stash_url_helpers.user_admin_profile_path(@user)
        expect(page).to have_css('button[title="Edit Dataset"]')
        find('button[title="Edit Dataset"]').click
        expect(page).to have_text("You are editing #{@user.name}'s dataset.")
        all('[id^=instit_affil_]').last.set('test institution')
        page.send_keys(:tab)
        page.has_css?('.use-text-entered')
        all(:css, '.use-text-entered').each { |i| i.set(true) }
        add_required_data_files
        click_link 'Review and submit'
        agree_to_everything
        expect(page).to have_css('input#user_comment')
      end

      it 'allows assigning a curator to a dataset', js: true do
        expect { @curator = create(:user, role: 'superuser', tenant_id: 'dryad') }.to change(StashEngine::User, :count).by(1)

        visit stash_url_helpers.ds_admin_path

        expect(page).to have_text('Admin dashboard')
        expect(page).to have_css('button[title="Update curator"]')
        find('button[title="Update curator"]').click
        find("#stash_engine_resource_current_editor_id option[value='#{@curator.id}']").select_option
        click_button('Submit')

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text(@curator.name.to_s)
        end

      end

      it 'allows un-assigning a curator, keeping status if it is peer_review', js: true do
        @curator = create(:user, role: 'superuser', tenant_id: 'dryad')
        expect { create(:curation_activity, resource: @resource, status: 'peer_review', note: 'forcing to peer_review') }
          .to change(StashEngine::CurationActivity, :count).by(1)
        @resource.reload

        visit stash_url_helpers.ds_admin_path

        expect(page).to have_text('Admin dashboard')
        expect(page).to have_css('button[title="Update curator"]')
        find('button[title="Update curator"]').click
        find("#stash_engine_resource_current_editor_id option[value='#{@curator.id}']").select_option
        click_button('Submit')
        find('button[title="Update curator"]').click
        find("#stash_engine_resource_current_editor_id option[value='0']").select_option
        click_button('Submit')
        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).not_to have_text(@curator.name_last_first)
        end
        @resource.reload

        expect(@resource.current_editor_id).to eq(nil)
        expect(@resource.current_curation_status).to eq('peer_review')
      end

      it 'allows un-assigning a curator, changing status if it is curation', js: true do
        @curator = create(:user, role: 'superuser', tenant_id: 'dryad')
        expect { create(:curation_activity, resource: @resource, status: 'curation', note: 'forcing to curation') }
          .to change(StashEngine::CurationActivity, :count).by(1)
        @resource.reload

        visit stash_url_helpers.ds_admin_path

        expect(page).to have_text('Admin dashboard')
        expect(page).to have_css('button[title="Update curator"]')

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text('Curation')
        end

        find('button[title="Update curator"]').click
        find("#stash_engine_resource_current_editor_id option[value='#{@curator.id}']").select_option
        click_button('Submit')
        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text(@curator.name)
        end
        find('button[title="Update curator"]').click
        find("#stash_engine_resource_current_editor_id option[value='0']").select_option
        click_button('Submit')
        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).not_to have_text(@curator.name)
        end
        @resource.reload

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text('Submitted')
        end
      end
    end

    context :user_admin do
      before(:each) do
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

      # TODO: THis needs fixing because the order of the merge is non-deterministic and tests fail
      xit 'allows merging users as a superuser', js: true do
        user = create(:user)
        user2 = create(:user)
        user_id = user.id
        user2_id = user2.id

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
        find('button[title="Merge selected"]').click
        expect(page).to have_text('Merge users')
        click_button('Merge')
        expect(page).to have_text('Manage users')

        sleep 1 # since it takes some time for async action to reflect in db
        # user_2 should be removed, modified check because of some weird caching or something
        expect(StashEngine::User.all.map(&:id)).not_to include(user2_id)

        # user should be updated with new values
        user_after = StashEngine::User.find(user_id)
        expect(user_after.email).to eq(target_email)
        expect(user_after.orcid).to eq(target_orcid)
      end
    end

    context :limited_curator, js: true do

      before(:each) do
        @user.update(role: 'limited_curator')
        sign_in(@user, false)
      end

      it 'shows limited menus to an administrative curator' do
        find('.c-header_nav-button', text: 'Datasets').click
        page.has_link?('Dataset curation')
        expect(page).to have_link('Dataset curation')
        expect(page).to have_link('Curation stats')
        expect(page).to have_link('Journals')
        expect(page).not_to have_link('User management')
        expect(page).not_to have_link('Submission queue')
      end

      # TODO: is there a way to make this test reliable on github?
      xit 'Limits options in the curation page' do
        find('.c-header_nav-button', text: 'Datasets').click
        page.has_link?('Dataset curation')
        click_on('Dataset curation')
        # select 'Status', from: 'curation_status'
        # find('#curation_status').set("Status\n") # trying to get headless to work reliably
        visit('/stash/ds_admin?utf8=✓') # remove the filter and load page which the JS action doesn't seem to be reliable on github
        # page.find('#js-curation-state-1', wait: 5) # might this make intermittent weirdness better on github servers?

        # expect(page).to have_selector('#js-curation-state-1')
        expect(page).to have_content(@resource.title)
        expect(page).not_to have_css('.fa-pencil') # no pencil editing icons for you
      end
    end

    context :journal_admin, js: true do
      before(:each) do
        @journal = create(:journal)
        @journal_admin = create(:user, tenant_id: 'mock_tenant')
        @journal_role = create(:journal_role, journal: @journal, user: @journal_admin, role: 'admin')
        @journal_admin.reload

        sign_in(@journal_admin, false)
      end

      it 'has admin link' do
        visit root_path
        find('.c-header_nav-button', text: 'Datasets').click
        expect(page).to have_link('Admin')
      end

      it 'only shows datasets from the target journal' do
        ident1 = create(:identifier)
        res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @admin.tenant_id)
        ident2 = create(:identifier)
        res2 = create(:resource, identifier_id: ident2.id, user: @user, tenant_id: @admin.tenant_id)
        StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationISSN', value: @journal.single_issn)
        StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationName', value: @journal.title)
        ident1.reload

        find('.c-header_nav-button', text: 'Datasets').click
        page.has_link?('Admin')
        click_link('Admin')
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(res1.title)
        expect(page).to_not have_text(res2.title)
      end
    end

    context :tenant_curator, js: true do

      before(:each) do
        mock_salesforce!
        @tenant_curator = create(:user, role: 'tenant_curator', tenant_id: 'mock_tenant')
        sign_in(@tenant_curator, false)
      end

      it 'has admin link' do
        visit root_path
        section = find('.c-header_nav-button', text: 'Datasets').text
        expect(section).to eq('Datasets')
      end
    end

  end
end
