require 'rails_helper'
RSpec.feature 'NewCollection', type: :feature do

  include CollectionHelper
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Datacite

  before(:each) do
    mock_salesforce!
    mock_solr!
    mock_good_doi_resolution(doi: %r{.*/doi\.org/.*})
    @user = create(:user, role: 'curator')
    sign_in(@user)
  end

  context :doi_generation do
    before(:each) do
      @identifier_count = StashEngine::Identifier.all.length
      @resource_count = StashEngine::Resource.all.length
    end

    it 'displays an error message if unable to mint a new DOI/ARK' do
      allow(Stash::Doi::DataciteGen).to receive(:new).and_raise(Stash::Doi::DataciteError)
      visit('/resources/new?collection')
      expect(page).to have_text('My datasets')
      expect(page).to have_text('Unable to register a DOI at this time. Please contact help@datadryad.org for assistance.')
      expect(StashEngine::Identifier.all.length).to eql(@identifier_count)
      expect(StashEngine::Resource.all.length).to eql(@resource_count)
    end

    it 'successfully mints a new DOI/ARK', js: true do
      visit('/resources/new?collection')
      expect(StashEngine::Identifier.all.length).to eql(@identifier_count + 1)
      expect(StashEngine::Resource.all.length).to eql(@resource_count + 1)

      # 'does not have files or readme'
      expect(page).not_to have_button('README')
      expect(page).not_to have_button('Files')
    end
  end

  # tests below are very slow

  context :requirements_met, js: true do
    before(:each, js: true) do
      create_datasets
      visit('/resources/new?collection')
      fill_required_fields
      navigate_to_review
      fill_in 'user_comment', with: Faker::Lorem.sentence
    end

    xit 'shows collected datasets & submits', js: true do
      expect(page).to have_text('Collected datasets')
      expect(page).to have_selector('li[id^="col"]', count: 3)

      # submit button should be enabled
      submit = find_button('submit_button', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit['aria-disabled']).to be false

      # submits
      submit_form
      expect(page).to have_content(StashEngine::Resource.last.title)
      expect(page).to have_content('submitted with DOI')
    end
  end

  context :edit_link do
    xit 'opens a page with an edit link and redirects when complete', js: true do
      create_datasets
      @identifier = create(:identifier)
      @identifier.edit_code = Faker::Number.number(digits: 5)
      @identifier.save
      @res = create(:resource, identifier: @identifier)
      create(:resource_type_collection, resource: @res)
      # Edit link for the above collection, including a returnURL that should redirect to a documentation page
      visit "/edit/#{@identifier.identifier}/#{@identifier.edit_code}?returnURL=%2Fstash%2Fsubmission_process"
      click_button 'Authors'
      all('[id^=instit_affil_]').last.set('test institution')
      page.send_keys(:tab)
      page.has_css?('.use-text-entered')
      all(:css, '.use-text-entered').each { |i| i.set(true) }
      click_button 'Subjects'
      fill_in_keywords
      click_button 'Related works'
      fill_in_collection
      navigate_to_review
      fill_in 'user_comment', with: Faker::Lorem.sentence
      submit_form
      expect(page.current_path).to eq('/submission_process')
    end
  end
end
