require 'pry'
require 'webmock/rspec'
RSpec.feature 'Populate manuscript metadata from outside source', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::LinkOut
  include Mocks::Salesforce
  include Mocks::Datacite

  before(:each) do
    mock_solr!
    mock_salesforce!
    mock_link_out!
  end

  context :journal_metadata_autofill, js: true do
    before(:each) do
      sign_in
      start_new_dataset
    end

    it 'gives disable submit manuscript not filled' do
      navigate_to_metadata
      within_fieldset('Is your dataset associated with a preprint, an article, or a manuscript submitted to a journal?') do
        find(:label, 'No').click
      end
      expect(page).not_to have_content('Which would you like to connect?')
    end

  end

  context :crossref_metadata_autofill, js: true do
    before(:each) do
      sign_in
      start_new_dataset
    end

    it 'does not allow import with no doi filled in' do
      doi = ''
      fill_crossref_info(doi: doi)
      expect(page).not_to have_button('Import metadata')
    end

    it 'works for successful dataset request to crossref', js: true do
      stub_request(:get, 'https://api.crossref.org/works/10.1098%2Frsif.2017.0030')
        .to_return(status: 200,
                   body: File.new(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', 'crossref_response.json')),
                   headers: {})

      doi = '10.1098/rsif.2017.0030'
      mock_good_doi_resolution(doi: "https://doi.org/#{doi}")
      fill_crossref_info(doi: doi)
      click_button 'Next'
      expect(page).to have_button('Import metadata')
      click_button('Import metadata')
      expect(page).to have_content('High-skilled labour mobility in Europe before and after the 2004 enlargement')
    end

    it 'works for successful dataset request to datacite', js: true do
      stub_request(:get, 'https://api.crossref.org/works/10.48550%2Farxiv.2601.20261')
        .to_return(status: 404,
                   body: 'not found',
                   headers: {})
      stub_request(:get, 'https://api.test.datacite.org/dois/10.48550%2Farxiv.2601.20261')
        .to_return(status: 200,
                   body: File.new(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', 'crossref_response.json')),
                   headers: {})

      doi = '10.48550/arxiv.2601.20261'
      mock_good_doi_resolution(doi: "https://doi.org/#{doi}")
      fill_crossref_info(doi: doi)
      click_button 'Next'
      expect(page).to have_button('Import metadata')
      click_button('Import metadata')
      expect(page).to have_content('Soft X-ray Reflection Ptychography')
    end

    it "gives a message when it can't find a doi" do
      stub_request(:get, 'https://api.crossref.org/works/10.0000%2Fbad.test.doi')
        .to_return(status: 404,
                   body: 'not found',
                   headers: {})
      stub_request(:get, 'https://api.test.datacite.org/dois/10.0000%2Fbad.test.doi')
        .to_return(status: 404,
                   body: 'not found',
                   headers: {})
      doi = '10.0000/bad.test.doi'
      mock_bad_doi_resolution(doi: "https://doi.org/#{doi}")
      fill_crossref_info(doi: doi)
      expect(page).to have_field('publication_published')
      click_button 'Next'
      expect(page).to have_button('Import metadata')
      click_button('Import metadata')
      expect(page.find('#population-warnings')).to have_content(
        "We couldn't find metadata to import for this DOI. Please fill in your title manually", wait: 15
      )
    end

  end
end
