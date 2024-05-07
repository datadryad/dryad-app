require 'pry-remote'

RSpec.feature 'UserAdmin', type: :feature do

  include DatasetHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::DataFile

  context :user_admin do

    before(:each) do
      mock_salesforce!
      mock_solr!
      mock_stripe!
      mock_datacite_gen!
      neuter_curation_callbacks!
      @superuser = create(:user, role: 'superuser')
      sign_in(@superuser, false)
    end

    it 'allows filtering by institution', js: true do
      expect do
        @user1 = create(:user, tenant_id: 'match_tenant')
        @user2 = create(:user, tenant_id: 'ucop')
      end.to change(StashEngine::User, :count).by(2)
      visit stash_url_helpers.user_admin_path
      select 'Match Tenant', from: 'tenant_id'
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

    it 'allows changing user tenant as a superuser', js: true do
      dryad = create(:tenant_dryad)
      expect { @user = create(:user) }.to change(StashEngine::User, :count).by(1)
      visit stash_url_helpers.user_admin_path
      expect(page).to have_link(@user.name)
      within(:css, "form[action=\"#{stash_url_helpers.user_tenant_popup_path(@user.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#tenant').click
        find("option[value='dryad']").select_option
        find('input[name=commit]').click
      end
      expect(page.find("#user_tenant_#{@user.id}")).to have_text(dryad.short_name)
      user_changed = StashEngine::User.find(@user.id)
      expect(user_changed.tenant_id).to eq(dryad.id)
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

    describe 'User admin - user profile page' do

      describe 'General profile edits' do
        before(:each) do
          @dryad = create(:tenant_dryad)
          expect { @user = create(:user) }.to change(StashEngine::User, :count).by(1)
          visit stash_url_helpers.user_admin_profile_path(@user.id)
        end

        it 'allows changing user email as a superuser', js: true do
          expect(page).to have_content(@user.name)
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

        it 'allows changing user tenant as a superuser', js: true do
          expect(page).to have_content(@user.name)
          within(:css, "form[action=\"#{stash_url_helpers.user_tenant_popup_path(@user.id)}\"]") do
            find('.c-admin-edit-icon').click
          end
          within(:css, '#genericModalDialog') do
            find('#tenant').click
            find("option[value='dryad']").select_option
            find('input[name=commit]').click
          end
          expect(page.find("#user_tenant_#{@user.id}")).to have_text(@dryad.short_name)
          user_changed = StashEngine::User.find(@user.id)
          expect(user_changed.tenant_id).to eq(@dryad.id)
        end

        it 'opens the user roles form', js: true do
          expect(page).to have_content(@user.name)
          find('#edit_roles').click
          expect(page).to have_content('Dryad system roles')
        end
      end

      describe 'User roles form', js: true do
        before(:each) do
          expect { @user = create(:user) }.to change(StashEngine::User, :count).by(1)
        end

        it 'shows the system roles selection' do
          visit "#{stash_url_helpers.user_admin_profile_path(@user.id)}#edit_roles"
          expect(page).to have_content('Dryad system roles')
        end
        it 'does not show the tenant form for the default tenant' do
          visit "#{stash_url_helpers.user_admin_profile_path(@user.id)}#edit_roles"
          expect(page).not_to have_content('Add a tenant role')
        end

        describe 'Adding and setting' do
          before(:each) do
            create(:tenant_dryad)
            create(:journal_organization)
            create(:journal)
            create(:funder)
            @user.update(tenant_id: 'dryad')
            visit "#{stash_url_helpers.user_admin_profile_path(@user.id)}#edit_roles"
          end

          it 'allows the superuser to set the system role' do
            find('#role_admin').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).to have_text('Admin')
            user_changed = StashEngine::User.find(@user.id)
            expect(user_changed.roles.system_roles.first.role).to eq('admin')
          end

          it 'allows the superuser to add the tenant role form' do
            find_button('Add a tenant role').click
            expect(page).to have_text('Tenant roles')
          end
          it 'allows the superuser to set the tenant role' do
            find_button('Add a tenant role').click
            find('#tenant_role_admin').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).to have_text('Tenant admin')
            user_changed = StashEngine::User.find(@user.id)
            expect(user_changed.roles.tenant_roles.first.role).to eq('admin')
          end

          it 'allows the superuser to add the publisher role form' do
            find_button('Add a publisher role').click
            expect(page).to have_text('Publisher roles')
          end
          it 'allows the superuser to set the publisher role' do
            find_button('Add a publisher role').click
            find('#publisher_role_admin').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).to have_text('Publisher admin')
            user_changed = StashEngine::User.find(@user.id)
            expect(user_changed.roles.journal_org_roles.first.role).to eq('admin')
          end

          it 'allows the superuser to add the journal role form' do
            find_button('Add a journal role').click
            expect(page).to have_text('Journal roles')
          end
          it 'allows the superuser to set the journal role' do
            find_button('Add a journal role').click
            find('#journal_role_admin').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).to have_text('Journal admin')
            user_changed = StashEngine::User.find(@user.id)
            expect(user_changed.roles.journal_roles.first.role).to eq('admin')
          end

          it 'allows the superuser to add the funder role form' do
            find_button('Add a funder role').click
            expect(page).to have_text('Funder roles')
          end
          it 'allows the superuser to set the funder role' do
            find_button('Add a funder role').click
            find('#funder_role_admin').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).to have_text('Funder admin')
            user_changed = StashEngine::User.find(@user.id)
            expect(user_changed.roles.funder_roles.first.role).to eq('admin')
          end
        end

        describe 'Users with roles' do
          describe 'system role' do
            before(:each) do
              create(:role, user: @user)
              visit "#{stash_url_helpers.user_admin_profile_path(@user.id)}#edit_roles"
            end
            it 'allows the superuser to change the system role' do
              find('#role_curator').set(true)
              find('input[name=commit]').click
              expect(page.find("#user_role_#{@user.id}")).to have_text('Curator')
              user_changed = StashEngine::User.find(@user.id)
              expect(user_changed.roles.system_roles.first.role).to eq('curator')
            end
            it 'allows the superuser to remove the system role' do
              find('#role_').set(true)
              find('input[name=commit]').click
              expect(page.find("#user_role_#{@user.id}")).not_to have_text('Funder admin')
              user_changed = StashEngine::User.find(@user.id)
              expect(user_changed.roles.system_roles).to be_empty
            end
          end

          describe 'tenant role' do
            before(:each) do
              create(:tenant_dryad)
              @user.update(tenant_id: 'dryad')
              create(:role, user: @user, role_object: @user.tenant)
              visit "#{stash_url_helpers.user_admin_profile_path(@user.id)}#edit_roles"
            end
            it 'shows the form if user has tenant role' do
              expect(page).to have_text('Tenant roles')
              expect(find_field('tenant_role_admin')).to be_checked
            end
            it 'allows the superuser to change the tenant role' do
              find('#tenant_role_curator').set(true)
              find('input[name=commit]').click
              expect(page.find("#user_role_#{@user.id}")).to have_text('Tenant curator')
              user_changed = StashEngine::User.find(@user.id)
              expect(user_changed.roles.tenant_roles.first.role).to eq('curator')
            end
            it 'allows the superuser to remove the tenant role' do
              find('#tenant_role_').set(true)
              find('input[name=commit]').click
              expect(page.find("#user_role_#{@user.id}")).not_to have_text('Tenant admin')
              user_changed = StashEngine::User.find(@user.id)
              expect(user_changed.roles.funder_roles).to be_empty
            end
          end

          describe 'publisher role' do
            before(:each) do
              org = create(:journal_organization)
              create(:role, user: @user, role_object: org)
              visit "#{stash_url_helpers.user_admin_profile_path(@user.id)}#edit_roles"
            end
            it 'shows the form if user has publisher role' do
              expect(page).to have_text('Publisher roles')
              expect(find_field('publisher_role_admin')).to be_checked
            end
            it 'allows the superuser to change the publisher role' do
              find('#publisher_role_curator').set(true)
              find('input[name=commit]').click
              expect(page.find("#user_role_#{@user.id}")).to have_text('Publisher curator')
              user_changed = StashEngine::User.find(@user.id)
              expect(user_changed.roles.journal_org_roles.first.role).to eq('curator')
            end
            it 'allows the superuser to remove the publisher role' do
              find('#publisher_role_').set(true)
              find('input[name=commit]').click
              expect(page.find("#user_role_#{@user.id}")).not_to have_text('Publisher admin')
              user_changed = StashEngine::User.find(@user.id)
              expect(user_changed.roles.journal_org_roles).to be_empty
            end
          end

          describe 'journal role' do
            before(:each) do
              journal = create(:journal)
              create(:role, user: @user, role_object: journal)
              visit "#{stash_url_helpers.user_admin_profile_path(@user.id)}#edit_roles"
            end
            it 'shows the form if user has journal role' do
              expect(page).to have_text('Journal roles')
              expect(find_field('journal_role_admin')).to be_checked
            end
            it 'allows the superuser to change the journal role' do
              find('#journal_role_curator').set(true)
              find('input[name=commit]').click
              expect(page.find("#user_role_#{@user.id}")).to have_text('Journal curator')
              user_changed = StashEngine::User.find(@user.id)
              expect(user_changed.roles.journal_roles.first.role).to eq('curator')
            end
            it 'allows the superuser to remove the journal role' do
              find('#journal_role_').set(true)
              find('input[name=commit]').click
              expect(page.find("#user_role_#{@user.id}")).not_to have_text('Journal admin')
              user_changed = StashEngine::User.find(@user.id)
              expect(user_changed.roles.journal_roles).to be_empty
            end
          end

          describe 'funder role' do
            before(:each) do
              funder = create(:funder)
              create(:role, user: @user, role_object: funder)
              visit "#{stash_url_helpers.user_admin_profile_path(@user.id)}#edit_roles"
            end
            it 'shows the form if user has funder role' do
              expect(page).to have_text('Funder roles')
              expect(find_field('funder_role_admin')).to be_checked
            end
            it 'allows the superuser to remove the funder role' do
              find('#funder_role_').set(true)
              find('input[name=commit]').click
              expect(page.find("#user_role_#{@user.id}")).not_to have_text('Funder admin')
              user_changed = StashEngine::User.find(@user.id)
              expect(user_changed.roles.funder_roles).to be_empty
            end
          end
        end
      end
    end
  end
end
