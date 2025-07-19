require 'pry'
require 'webmock/rspec'
RSpec.feature 'Populate manuscript metadata from outside source', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::LinkOut
  include Mocks::Salesforce

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
      expect(page).not_to have_button('Import metadata')
    end

  end

  context :crossref_metadata_autofill, js: true do
    before(:each) do
      sign_in
      start_new_dataset
    end

    it 'works for successful dataset request to crossref', js: true do
      stub_request(:get, 'https://api.crossref.org/works/10.1098%2Frsif.2017.0030')
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 200,
                   body: File.new(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', 'crossref_response.json')),
                   headers: {})

      stub_request(:head, 'https://doi.org/10.1098/rsif.2017.0030').with(
        headers: { 'Host' => 'doi.org' }
      ).to_return(status: 200, body: '', headers: {})

      journal = 'Journal of The Royal Society Interface'
      doi = '10.1098/rsif.2017.0030'
      fill_crossref_info(name: journal, doi: doi)
      expect(page).to have_button('Import metadata')
      click_button('Import metadata')
      expect(page).to have_field('title',
                                 with: 'High-skilled labour mobility in Europe before and after the 2004 enlargement')
    end

    it 'gives message for no doi filled in' do
      journal = ''
      doi = ''
      fill_crossref_info(name: journal, doi: doi)
      expect(page).not_to have_button('Import metadata')
    end

    it "gives a message when it can't find a doi" do
      stub_request(:get, %r{\Ahttps://api.crossref.org/.+\z})
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => /.*/,
            'User-Agent' => /.*/,
            'X-User-Agent' => /.*/
          }
        )
        .to_return(status: 404,
                   body: 'not found',
                   headers: {})
      journal = 'cats'
      doi = 'scabs'
      fill_crossref_info(name: journal, doi: doi)
      expect(page).to have_button('Import metadata')
      click_button('Import metadata')
      expect(page.find('#population-warnings')).to have_content(
        "We couldn't find metadata to import for this DOI. Please fill in your title manually", wait: 15
      )
    end

  end
end
