RSpec.feature 'JournalAdmin', type: :feature do

  context :journal_admin do

    before(:each) do
      create(:tenant)
      3.times { @journal = create(:journal) }
      @superuser = create(:user, role: 'superuser', tenant_id: 'dryad')
      sign_in(@superuser, false)
    end

    it 'allows filtering by sponsor', js: true do
      org = create(:journal_organization)
      journal = create(:journal)
      journal.update(sponsor_id: org.id)
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      select org.name, from: 'sponsor'
      click_on 'Search'
      expect(page).to have_content(journal.title)
      expect(page).not_to have_content(@journal.title)
    end

    it 'allows changing ISSNs as a superuser', js: true do
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_popup_path(id: @journal.id, field: 'issn')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#issn').set('1111-2222')
        find('input[name=commit]').click
      end
      expect(page.find("#issn_#{@journal.id}")).to have_text('1111-2222')
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.issn_array).to include('1111-2222')
    end

    it 'allows changing notify contacts as a superuser', js: true do
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_popup_path(id: @journal.id, field: 'notify_contacts')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#notify_contacts').set('test@email.com')
        find('input[name=commit]').click
      end
      expect(page.find("#notify_contacts_#{@journal.id}")).to have_text('test@email.com')
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.notify_contacts).to include('test@email.com')
    end

    it 'allows changing review contacts as a superuser', js: true do
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_popup_path(id: @journal.id, field: 'review_contacts')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#review_contacts').set('test@email.com')
        find('input[name=commit]').click
      end
      expect(page.find("#review_contacts_#{@journal.id}")).to have_text('test@email.com')
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.review_contacts).to include('test@email.com')
    end

    it 'allows changing ppr default as a superuser', js: true do
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_popup_path(id: @journal.id, field: 'default_to_ppr')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#default_to_ppr').click
        find('input[name=commit]').click
      end
      expect(page.find("#default_to_ppr_#{@journal.id}")).to have_text('True')
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.default_to_ppr).to be true
    end

    it 'allows changing sponsor as a superuser', js: true do
      org = create(:journal_organization)
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_popup_path(id: @journal.id, field: 'sponsor_id')}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find("option[value='#{org.id}']").select_option
        find('input[name=commit]').click
      end
      expect(page.find("#sponsor_id_#{@journal.id}")).to have_text(org.name)
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.sponsor_id).to be org.id
    end

  end
end
