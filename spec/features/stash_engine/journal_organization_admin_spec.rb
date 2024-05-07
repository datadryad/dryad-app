RSpec.feature 'JournalOrganizationAdmin', type: :feature do

  context :journal_organization_admin do

    before(:each) do
      create(:tenant)
      3.times do
        @org = create(:journal_organization)
        3.times { @journal = create(:journal, sponsor_id: @org.id) }
      end
      @superuser = create(:user, role: 'superuser', tenant_id: 'dryad')
      sign_in(@superuser, false)
    end

    it 'lists journals', js: true do
      visit stash_url_helpers.publisher_admin_path
      expect(page).to have_content(@org.name)
      expect(page).to have_content(@journal.title)
    end

    it 'allows filtering by parent org', js: true do
      org = create(:journal_organization)
      2.times { create(:journal, sponsor_id: org.id) }
      parent = create(:journal_organization)
      org.update(parent_org_id: parent.id)
      visit stash_url_helpers.publisher_admin_path
      expect(page).to have_content(@org.name)
      select parent.name, from: 'sponsor'
      click_on 'Search'
      expect(page).to have_content(org.name)
      expect(page).not_to have_content(@org.name)
    end

    it 'allows changing contacts as a superuser', js: true do
      visit stash_url_helpers.publisher_admin_path
      expect(page).to have_content(@org.name)
      within(:css, "form[action=\"#{publisher_popup_path(id: @org.id, field: 'contact')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#contact').set('test@email.com')
        find('input[name=commit]').click
      end
      expect(page.find("#contact_#{@org.id}")).to have_text('test@email.com')
      changed = StashEngine::JournalOrganization.find(@org.id)
      expect(changed.contact).to include('test@email.com')
    end

    it 'allows changing sponsor as a superuser', js: true do
      org = create(:journal_organization)
      visit stash_url_helpers.publisher_admin_path
      expect(page).to have_content(@org.name)
      within(:css, "form[action=\"#{publisher_popup_path(id: @org.id, field: 'parent_org_id')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find("option[value='#{org.id}']").select_option
        find('input[name=commit]').click
      end
      expect(page.find("#parent_org_id_#{@org.id}")).to have_text(org.name)
      changed = StashEngine::JournalOrganization.find(@org.id)
      expect(changed.parent_org_id).to be org.id
    end

  end
end
