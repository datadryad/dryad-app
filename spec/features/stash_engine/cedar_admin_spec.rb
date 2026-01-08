RSpec.feature 'CedarAdmin', type: :feature, js: true do

  context :cedar_admin do

    before(:each) do
      @mock = create(:tenant)
      @system_admin = create(:user, role: 'manager')
      sign_in(@system_admin, false)
      2.times { create(:cedar_word_bank) }
    end

    describe :word_banks do
      it 'adds a new word bank' do
        visit stash_url_helpers.cedar_word_bank_path
        click_button 'Add new'
        expect(page).to have_content('Create a new word bank')
        within(:css, '#genericModalDialog') do
          fill_in 'label', with: 'New word bank'
          fill_in 'keywords', with: 'some|test|words'
          find('input[name=commit]').click
        end
        expect(page).to have_content 'New word bank'
        expect(CedarWordBank.all.length).to eql(3)
      end
    end

    describe :templates do
      it 'adds a new template' do
        visit stash_url_helpers.cedar_template_path
        click_button 'Add new'
        expect(page).to have_content('New CEDAR template')
        within(:css, '#genericModalDialog') do
          attach_file('file-select', "#{Rails.root}/spec/fixtures/stash_engine/cedar.json")
          expect(page).to have_text('This is just a test')
          first('#word_bank_id option:nth-of-type(2)').select_option
          find('input[name=commit]').click
        end
        expect(page).to have_content 'This is just a test'
        expect(CedarTemplate.all.length).to eql(1)
      end
    end
  end
end
