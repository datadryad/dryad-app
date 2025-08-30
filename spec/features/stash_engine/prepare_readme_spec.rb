RSpec.feature 'PrepareReadme', type: :feature, js: true do
  include DatasetHelper

  describe :prepare_readme do
    let(:user) { create(:user) }
    let(:resource) { create(:resource, user: user) }

    before(:each) do
      resource.identifier.reload
      @file = create(:data_file, resource: resource)
      allow_any_instance_of(StashEngine::DataFile).to receive(:uploaded).and_return(true)
      sign_in(user)
    end

    context 'use README wizard' do
      it 'creates a README with title and file name' do
        click_button 'Resume'
        expect(page).to have_text 'Dataset submission'
        click_button 'README'
        click_button 'Build a README'
        find('[name="data_description"]').send_keys(Faker::Lorem.sentence)
        expect(page).to have_text('All progress saved')
        click_button 'readme-next'
        find('[name="files_and_variables"]').send_keys('test')
        page.send_keys(:tab)
        expect(page).to have_text('All progress saved')
        click_button 'readme-next'
        click_button 'readme-next'
        click_button 'readme-next'
        expect(page).to have_content('To help others interpret and reuse your dataset, a README file must be included')
        expect(page).to have_text(resource.title)
        expect(page).to have_text(@file.download_filename)
      end
    end

    context 'reflect edits in README' do
      before(:each) do
        # rubocop:disable Layout/LineLength
        create(:description, resource: resource, description_type: 'technicalinfo', description: "# #{resource.title}\n\nDataset DOI: [#{resource.identifier_value}](#{resource.identifier_value})\n\n#### File: #{@file.download_filename}")
        # rubocop:enable Layout/LineLength
        resource.reload
        click_button 'Resume'
        expect(page).to have_text 'Dataset submission'
      end

      it 'displays the README content' do
        click_button 'README'
        expect(page).to have_content('To help others interpret and reuse your dataset, a README file must be included')
        expect(page).to have_text(resource.title)
        expect(page).to have_text(@file.download_filename)
      end

      it 'changes the title' do
        title = Faker::Hipster.sentence
        click_button 'Title'
        find('[name="title"]').set('')
        find('[name="title"]').send_keys(title)
        expect(page).to have_text('All progress saved')
        click_button 'README'
        expect(page).to have_content('To help others interpret and reuse your dataset, a README file must be included', wait: 10)
        expect(page).to have_text(title)
        expect(page).to have_text(@file.download_filename)
      end

      it 'changes the file name' do
        fname = Faker::Hipster.word
        click_button 'Files'
        click_button "Rename file #{@file.download_filename}"
        fill_in "Rename file #{@file.download_filename}", with: fname
        click_button "Save new name for #{@file.download_filename}"
        expect(page).to have_text('All progress saved')
        click_button 'README'
        expect(page).to have_content('To help others interpret and reuse your dataset, a README file must be included', wait: 10)
        expect(page).to have_text(resource.title)
        expect(page).to have_text(fname)
        expect(page).not_to have_text(@file.download_filename)
      end
    end
  end
end
