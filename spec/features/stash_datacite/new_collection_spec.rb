require 'rails_helper'
RSpec.feature 'NewCollection', type: :feature do

  include CollectionHelper
  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Datacite

  before(:each) do
    mock_salesforce!
    mock_solr!
    mock_good_doi_resolution(doi: %r{.*/doi\.org/.*})
    sign_in(create(:user, role: 'curator'))
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

      # 'does not have several sections'
      expect(page).not_to have_button('Compliance')
      expect(page).not_to have_button('README')
      expect(page).not_to have_button('Files')
    end
  end

  context :requirements_met, js: true do
    before(:each, js: true) do
      create_datasets
      visit('/resources/new?collection')
      fill_required_meta
      navigate_to_preview
    end

    it 'shows collected datasets & submits', js: true do
      expect(page).to have_text('Collected datasets')
      expect(page).to have_selector('li[id^="col"]', count: 3)

      # submit button should be enabled
      submit = find_button('submit_button', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit['aria-disabled']).to be nil

      # submits
      submit_form
      expect(page).to have_content(StashEngine::Resource.last.title)
      expect(page).to have_content("Your collection with the DOI #{StashEngine::Resource.last.identifier_uri} was submitted for curation")
    end
  end
end
