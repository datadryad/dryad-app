RSpec.feature 'JournalAdmin', type: :feature do

  context :journal_admin do

    before(:each) do
      create(:tenant)
      3.times { @journal = create(:journal) }
      @system_admin = create(:user, role: 'admin')
      sign_in(@system_admin, false)
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

    it 'allows changing ISSNs as a system admin', js: true do
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_edit_path(id: @journal.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#issn').set('1111-2222')
        find('input[name=commit]').click
      end
      expect(page.find("#row_#{@journal.id}")).to have_text('1111-2222')
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.issn_array).to include('1111-2222')
    end

    it 'allows changing notify contacts as a system admin', js: true do
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_edit_path(id: @journal.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#notify_contacts').set('test@email.com')
        find('input[name=commit]').click
      end
      expect(page.find("#row_#{@journal.id}")).to have_text('test@email.com')
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.notify_contacts).to include('test@email.com')
    end

    it 'allows changing review contacts as a system admin', js: true do
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_edit_path(id: @journal.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#review_contacts').set('test@email.com')
        find('input[name=commit]').click
      end
      expect(page.find("#row_#{@journal.id}")).to have_text('test@email.com')
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.review_contacts).to include('test@email.com')
    end

    it 'allows changing ppr default as a system admin', js: true do
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_edit_path(id: @journal.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#default_to_ppr').click
        find('input[name=commit]').click
      end
      expect(page.find("#row_#{@journal.id}")).to have_text('True')
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.default_to_ppr).to be true
    end

    it 'allows changing sponsor as a system admin', js: true do
      org = create(:journal_organization)
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_content(@journal.title)
      within(:css, "form[action=\"#{journal_edit_path(id: @journal.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find("option[value='#{org.id}']").select_option
        find('input[name=commit]').click
      end
      expect(page.find("#row_#{@journal.id}")).to have_text(org.name)
      changed = StashEngine::Journal.find(@journal.id)
      expect(changed.sponsor_id).to be org.id
    end

  end
end
