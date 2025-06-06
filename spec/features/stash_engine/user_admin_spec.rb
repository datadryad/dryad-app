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
      @system_admin = create(:user, role: 'admin')
      sign_in(@system_admin, false)
    end

    it 'allows filtering by institution', js: true do
      expect do
        @user1 = create(:user, tenant_id: 'match_tenant')
        @user2 = create(:user, tenant_id: 'ucop')
      end.to change(StashEngine::User, :count).by(2)
      visit stash_url_helpers.user_admin_path
      select 'Match Tenant', from: 'tenant_filter'
      click_on 'Search'
      expect(page).to have_link(@user1.name)
      expect(page).not_to have_link(@user2.name)
    end

    describe 'Editing users', js: true do
      before(:each) do
        expect { @user = create(:user) }.to change(StashEngine::User, :count).by(1)
        visit stash_url_helpers.user_admin_path
        expect(page).to have_link(@user.name)
      end

      it 'allows changing user email as a system admin', js: true do
        within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
          find('.c-admin-edit-icon').click
        end
        within(:css, '#genericModalDialog') do
          find('#email').set('new-email@example.org')
          find('input[name=commit]').click
        end
        expect(page.find("#user_email_#{@user.id}")).to have_text('new-email@example.org')
      end

      it 'allows changing user tenant as a system admin', js: true do
        dryad = create(:tenant_dryad)
        within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
          find('.c-admin-edit-icon').click
        end
        within(:css, '#genericModalDialog') do
          find('#tenant_id').click
          find("option[value='dryad']").select_option
          find('input[name=commit]').click
        end
        expect(page.find("#user_tenant_id_#{@user.id}")).to have_text(dryad.short_name)
      end

      it 'shows the system roles selection' do
        within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
          find('.c-admin-edit-icon').click
        end
        expect(page).to have_content('Dryad system roles')
        # it 'does not show the tenant form for the default tenant' do
        expect(page).not_to have_content('Add a tenant role')
      end

      describe 'Adding and setting roles' do
        before(:each) do
          create(:tenant_dryad)
          create(:journal_organization)
          @journal = create(:journal)
          create(:funder)
          @user.update(tenant_id: 'dryad')
          within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
            find('.c-admin-edit-icon').click
          end
        end

        it 'allows the system admin to set the system role' do
          find('#role_admin').set(true)
          find('input[name=commit]').click
          expect(page.find("#user_role_#{@user.id}")).to have_text('Admin')
        end

        it 'allows the system admin to add the tenant role form and set role' do
          find_button('Add a tenant role').click
          expect(page).to have_text('Tenant roles')
          find('#tenant_role_admin').set(true)
          find('input[name=commit]').click
          expect(page.find("#user_role_#{@user.id}")).to have_text('Tenant admin')
        end

        it 'allows the system admin to add the publisher role form and set role' do
          find_button('Add a publisher role').click
          expect(page).to have_text('Publisher roles')
          find('#publisher_role_admin').set(true)
          find('input[name=commit]').click
          expect(page.find("#user_role_#{@user.id}")).to have_text('Publisher admin')
        end

        it 'allows the system admin to add the journal role form and set role' do
          find_button('Add a journal role').click
          expect(page).to have_text('Journal roles')
          fill_in 'searchselect-journal__input', with: @journal.title
          find("li[data-value='#{@journal.id}']").click
          find('#journal_role_admin').set(true)
          find('input[name=commit]').click
          expect(page.find("#user_role_#{@user.id}")).to have_text('Journal admin')
        end

        it 'allows the system admin to add the funder role form and set role' do
          find_button('Add a funder role').click
          expect(page).to have_text('Funder roles')
          find('#funder_role_admin').set(true)
          find('input[name=commit]').click
          expect(page.find("#user_role_#{@user.id}")).to have_text('Funder admin')
        end
      end

      describe 'Users with roles' do
        describe 'no orcid users' do
          before(:each) do
            journal = create(:journal)
            create(:role, user: @user, role_object: journal)
            @user.update(orcid: nil)
            within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
              find('.c-admin-edit-icon').click
            end
          end
          it 'shows the button to create an API account' do
            expect(page).to have_text('API account')
            expect(page).to have_text('Create a Dryad API account')
          end
          it 'adds and shows API account information' do
            find_button("Create a Dryad API account for #{@user.name}").click
            expect(page).to have_text('Account ID')
            expect(page).to have_text('Secret')
          end
        end

        describe 'system role' do
          before(:each) do
            create(:role, user: @user)
            within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
              find('.c-admin-edit-icon').click
            end
          end
          it 'allows the system admin to change the system role' do
            find('#role_curator').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).to have_text('Curator')
          end
          it 'allows the system admin to remove the system role' do
            find('#role_').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).not_to have_text('Funder admin')
          end
        end

        describe 'tenant role' do
          before(:each) do
            create(:tenant_dryad)
            @user.update(tenant_id: 'dryad')
            create(:role, user: @user, role_object: @user.tenant)
            within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
              find('.c-admin-edit-icon').click
            end
            expect(page).to have_text('Tenant roles')
            expect(find_field('tenant_role_admin')).to be_checked
          end
          it 'allows the system admin to change the tenant role' do
            find('#tenant_role_curator').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).to have_text('Tenant curator')
          end
          it 'allows the system admin to remove the tenant role' do
            find('#tenant_role_').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).not_to have_text('Tenant admin')
          end
        end

        describe 'publisher role' do
          before(:each) do
            org = create(:journal_organization)
            create(:role, user: @user, role_object: org)
            within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
              find('.c-admin-edit-icon').click
            end
            expect(page).to have_text('Publisher roles')
            expect(find_field('publisher_role_admin')).to be_checked
          end
          it 'allows the system admin to change the publisher role' do
            find('#publisher_role_curator').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).to have_text('Publisher curator')
          end
          it 'allows the system admin to remove the publisher role' do
            find('#publisher_role_').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).not_to have_text('Publisher admin')
          end
        end

        describe 'journal role' do
          before(:each) do
            journal = create(:journal)
            create(:role, user: @user, role_object: journal)
            within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
              find('.c-admin-edit-icon').click
            end
            expect(page).to have_text('Journal roles')
            expect(find_field('journal_role_admin')).to be_checked
          end
          it 'allows the system admin to change the journal role' do
            find('#journal_role_curator').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).to have_text('Journal curator')
          end
          it 'allows the system admin to remove the journal role' do
            find('#journal_role_').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).not_to have_text('Journal admin')
          end
        end

        describe 'funder role' do
          before(:each) do
            funder = create(:funder)
            create(:role, user: @user, role_object: funder)
            within(:css, "form[action=\"#{stash_url_helpers.user_edit_path(id: @user.id)}\"]") do
              find('.c-admin-edit-icon').click
            end
            expect(page).to have_text('Funder roles')
            expect(find_field('funder_role_admin')).to be_checked
          end
          it 'allows the system admin to remove the funder role' do
            find('#funder_role_').set(true)
            find('input[name=commit]').click
            expect(page.find("#user_role_#{@user.id}")).not_to have_text('Funder admin')
          end
        end
      end
    end

    describe 'Merging' do
      before(:each) do
        @user = create(:user)
        @user2 = create(:user)
      end

      it 'does not allow merging users as a system_user', js: true do
        visit stash_url_helpers.user_admin_path
        expect(page).to have_link(@user.name)
        expect(page).to have_link(@user2.name)
        expect(page).not_to have_css("#user_ids_selections_#{@user.id}")
        expect(page).not_to have_css("#user_ids_selections_#{@user2.id}")
        expect(page).not_to have_button('Merge selected')
      end

      it 'allows merging users as a superuser', js: true do
        user_id = @user.id
        user2_id = @user2.id
        # Set some fields nil so we can test that the merge result contains the non-nil fields
        @user.update(email: nil)
        @user2.update(orcid: nil)
        target_email = @user2.email
        target_orcid = @user.orcid

        sign_in(create(:user, role: 'superuser'), false)

        visit stash_url_helpers.user_admin_path
        expect(page).to have_link(@user.name)
        expect(page).to have_link(@user2.name)

        # Click each select box
        find("#user_ids_selections_#{@user.id}").click
        find("#user_ids_selections_#{@user2.id}").click

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
end
