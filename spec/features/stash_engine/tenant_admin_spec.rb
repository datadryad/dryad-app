RSpec.feature 'TenantAdmin', type: :feature do

  context :tenant_admin do

    before(:each) do
      @mock = create(:tenant)
      @dryad = create(:tenant_dryad)
      @match = create(:tenant_match)
      @ucop = create(:tenant_ucop)
      @system_admin = create(:user, role: 'manager')
      sign_in(@system_admin, false)
    end

    it 'allows filtering by consortium', js: true do
      expect do
        create(:tenant, id: 'consortium', short_name: 'Consortium')
        create(:tenant, id: 'member1', short_name: 'Member 1', sponsor_id: 'consortium')
        create(:tenant, id: 'member2', short_name: 'Member 2', sponsor_id: 'consortium')
      end.to change(StashEngine::Tenant, :count).by(3)
      visit stash_url_helpers.tenant_admin_path
      select 'Consortium', from: 'consortium'
      click_on 'Search'
      expect(page).to have_content('Member 1')
      expect(page).to have_content('Member 2')
      expect(page).not_to have_content(@match.short_name)
    end

    it 'allows changing the logo as a system admin', js: true do
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_content(@match.short_name)
      within(:css, "form[action=\"#{tenant_edit_path(id: @match.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        attach_file('file-select', "#{Rails.root}/spec/fixtures/stash_engine/logo.png")
        expect(find('#file-preview img')[:src]).to eq(logo_image)
        find('input[name=commit]').click
      end
      expect(page.find("##{@match.id}_row img")[:src]).to eq(logo_image)
      changed = StashEngine::Tenant.find(@match.id)
      expect(changed.logo.data).to eq(logo_image)
    end

    it 'allows changing ROR IDs as a system admin', js: true do
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_content(@match.short_name)
      within(:css, "form[action=\"#{tenant_edit_path(id: @match.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#ror_orgs').set('https://ror.org/1234')
        find('input[name=commit]').click
      end
      expect(page.find("##{@match.id}_row")).to have_text('https://ror.org/1234')
      changed = StashEngine::Tenant.find(@match.id)
      expect(changed.ror_ids).to include('https://ror.org/1234')
    end

    it 'allows changing contacts as a system admin', js: true do
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_content(@match.short_name)
      within(:css, "form[action=\"#{tenant_edit_path(id: @match.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#campus_contacts').set('test@email.com')
        find('input[name=commit]').click
      end
      expect(page.find("##{@match.id}_row")).to have_text('test@email.com')
      changed = StashEngine::Tenant.find(@match.id)
      expect(changed.campus_contacts).to include('test@email.com')
    end

    it 'allows changing display as a system admin', js: true do
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_content(@match.short_name)
      within(:css, "form[action=\"#{tenant_edit_path(id: @match.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#partner_display').click
        find('input[name=commit]').click
      end
      expect(page.find("##{@match.id}_row")).to have_text('Hidden')
      changed = StashEngine::Tenant.find(@match.id)
      expect(changed.partner_display).to be false
    end

    it 'allows disabling as a system admin', js: true do
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_content(@match.short_name)
      within(:css, "form[action=\"#{tenant_edit_path(id: @match.id)}\"]") do
        find('.c-admin-edit-icon').click
      end
      within(:css, '#genericModalDialog') do
        find('#enabled').click
        find('input[name=commit]').click
      end
      expect(page.find("##{@match.id}_row")).to have_text('Disabled')
      changed = StashEngine::Tenant.find(@match.id)
      expect(changed.enabled).to be false
    end

  end
end

# rubocop:disable Layout/LineLength
def logo_image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAMAAAC6V+0/AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAaVBMVEUAAAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD///+kkpPsAAAAIXRSTlMABlem2PRWU93cUgOMiwKJUN5Vp6Ta8/HZ16NUBdtPiIq8tKWIAAAAAWJLR0QiXWVcrAAAAAd0SU1FB+cLFxUEFBnQr08AAACESURBVBjTbdDtEoIgFEXRg+BnSWpEkWjd93/JlGEsuO1/rhlkOMCeKKQqSyUrgaO6oVjbRTqd6adeB0yM6BLOUtaw3dHmOAoUxJpw5Whw46hgOdp/eMeDo4Pk+ETFcYZfcmu2qboc1/3xfWqvsJJ+JyPpuOhw/HdZv9P7yThrnZl9+PwAiOknqc4Zu0AAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjMtMTEtMjNUMjE6MDQ6MjArMDA6MDANo+62AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTExLTIzVDIxOjA0OjIwKzAwOjAwfP5WCgAAAABJRU5ErkJggg=='
# rubocop:enable Layout/LineLength
