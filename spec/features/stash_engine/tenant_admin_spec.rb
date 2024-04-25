RSpec.feature 'TenantAdmin', type: :feature do

  context :tenant_admin do

    before(:each) do
      @mock = create(:tenant)
      @dryad = create(:tenant_dryad)
      @match = create(:tenant_match)
      @ucop = create(:tenant_ucop)
      @superuser = create(:user, role: 'superuser', tenant_id: 'dryad')
      sign_in(@superuser, false)
    end

    it 'allows filtering by sponsor', js: true do
      expect do
        create(:tenant, id: 'consortium', short_name: 'Consortium')
        create(:tenant, id: 'member1', short_name: 'Member 1', sponsor_id: 'consortium')
        create(:tenant, id: 'member2', short_name: 'Member 2', sponsor_id: 'consortium')
      end.to change(StashEngine::Tenant, :count).by(3)
      visit stash_url_helpers.tenant_admin_path
      select 'Consortium', from: 'sponsor'
      click_on 'Search'
      expect(page).to have_content('Member 1')
      expect(page).to have_content('Member 2')
      expect(page).not_to have_content(@match.short_name)
    end

    it 'allows changing ROR IDs as a superuser', js: true do
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_content(@match.short_name)
      within(:css, "form[action=\"#{tenant_popup_path(id: @match.id, field: 'ror_orgs')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#ror_orgs').set('https://ror.org/1234')
        find('input[name=commit]').click
      end
      expect(page.find("#ror_orgs_#{@match.id}")).to have_text('https://ror.org/1234')
      changed = StashEngine::Tenant.find(@match.id)
      expect(changed.ror_ids).to include('https://ror.org/1234')
    end

    it 'allows changing contacts as a superuser', js: true do
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_content(@match.short_name)
      within(:css, "form[action=\"#{tenant_popup_path(id: @match.id, field: 'campus_contacts')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#campus_contacts').set('test@email.com')
        find('input[name=commit]').click
      end
      expect(page.find("#campus_contacts_#{@match.id}")).to have_text('test@email.com')
      changed = StashEngine::Tenant.find(@match.id)
      expect(changed.campus_contacts).to include('test@email.com')
    end

    it 'allows changing display as a superuser', js: true do
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_content(@match.short_name)
      within(:css, "form[action=\"#{tenant_popup_path(id: @match.id, field: 'partner_display')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#partner_display').click
        find('input[name=commit]').click
      end
      expect(page.find("#partner_display_#{@match.id}")).to have_text('Hidden')
      changed = StashEngine::Tenant.find(@match.id)
      expect(changed.partner_display).to be false
    end

    it 'allows disabling as a superuser', js: true do
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_content(@match.short_name)
      within(:css, "form[action=\"#{tenant_popup_path(id: @match.id, field: 'enabled')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#enabled').click
        find('input[name=commit]').click
      end
      expect(page.find("#enabled_#{@match.id}")).to have_text('Disabled')
      changed = StashEngine::Tenant.find(@match.id)
      expect(changed.enabled).to be false
    end

  end
end
