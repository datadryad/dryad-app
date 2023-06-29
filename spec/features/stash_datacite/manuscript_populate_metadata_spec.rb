require 'pry'
require 'webmock/rspec'
RSpec.feature 'Populate manuscript metadata from outside source', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::LinkOut
  include Mocks::Tenant
  include Mocks::Salesforce

  before(:each) do
    mock_solr!
    mock_salesforce!
    mock_link_out!
    mock_tenant!
  end

  context :journal_metadata_autofill, js: true do
    before(:each) do
      sign_in
      start_new_dataset
    end

    xit "gives message when journal isn't selected" do
      find('input[value="manuscript"]').click
      fill_manuscript_info(name: 'European Journal of Plant Pathology', issn: nil, msid: nil)
      click_button 'Import manuscript metadata'
      expect(page.find('div#population-warnings')).to have_content('Please select your journal from the autocomplete drop-down list')
    end

    it 'gives disable submit manuscript not filled' do
      choose('a manuscript in progress', allow_label_click: true)
      expect(page).to have_button('Import manuscript metadata', disabled: true)
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

      stub_request(:get, 'https://doi.org/10.1098/rsif.2017.0030').with(
        headers: { 'Host' => 'doi.org' }
      ).to_return(status: 200, body: '', headers: {})

      journal = 'Journal of The Royal Society Interface'
      doi = '10.1098/rsif.2017.0030'
      fill_crossref_info(name: journal, doi: doi)
      click_import_article_metadata
      expect(page).to have_field('title',
                                 with: 'High-skilled labour mobility in Europe before and after the 2004 enlargement')
    end

    it 'gives message for no doi filled in' do
      journal = ''
      doi = ''
      fill_crossref_info(name: journal, doi: doi)
      expect(page).to have_button('Import article metadata', disabled: true)
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
      click_import_article_metadata
      expect(page.find('div#population-warnings')).to have_content("We couldn't obtain information from CrossRef about this DOI", wait: 15)
    end

    def click_import_article_metadata
      # Tell the form that we're really doing the import and not just an ajax autocomplete.
      # For normal use, this is set by javascript, but within rspec, it wasn't working properly,
      # so we force it here.
      page.execute_script("$('#do_import').val('true')")

      click_button 'Import article metadata'
    end

  end
end
