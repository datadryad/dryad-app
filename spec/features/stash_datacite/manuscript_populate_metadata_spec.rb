require 'pry'
require 'webmock/rspec'
RSpec.feature 'Populate manuscript metadata from outside source', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::LinkOut
  include Mocks::Tenant

  before(:each) do
    mock_solr!
    mock_link_out!
    mock_tenant!
  end

  context :journal_metadata_autofill, js: true do
    before(:each) do
      sign_in
      start_new_dataset
    end

    xit 'warns when dataset info could not be found' do
      # this stubs the old dryad api tha Daisie was calling, soon to be changed more
      stub_request(:get, 'https://api.datadryad.example.org/api/v1/organizations/1573-8469/manuscripts/APPS-D-grog-plant0001221?access_token=bad_token')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 404, body: '', headers: {})
      find('input[value="manuscript"]').click
      fill_manuscript_info(name: 'European Journal of Plant Pathology', issn: '1573-8469', msid: 'APPS-D-grog-plant0001221')
      click_button 'Import Manuscript Metadata', wait: 7
      expect(page.find('div#population-warnings')).to have_content('We could not find metadata to import for this manuscript. ' \
          'Please enter your metadata below.', wait: 30)
    end

    xit "gives message when journal isn't selected" do
      find('input[value="manuscript"]').click
      fill_manuscript_info(name: 'European Journal of Plant Pathology', issn: nil, msid: nil)
      click_button 'Import Manuscript Metadata', wait: 7
      expect(page.find('div#population-warnings')).to have_content('Please select your journal from the autocomplete drop-down list', wait: 20)
    end

    it "gives message when form isn't filled" do
      find('input[value="manuscript"]').click
      click_button 'Import Manuscript Metadata', wait: 7
      expect(page.find('div#population-warnings')).to have_content('Please fill in the form completely', wait: 15)
    end

    # Commenting this one out for now. seems to fail randomly
    xit 'works for successful request to Dryad manuscript API' do
      stub_request(:get, 'https://api.datadryad.example.org/api/v1/organizations/1759-6831/manuscripts/JSE-2017-12-137?access_token=bad_token')
        .with(
          headers: {
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 200,
                    body: File.new(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', 'dryad_manuscript.json')),
                    headers: { 'Content-Type' => 'application/json' })
      journal = 'Journal of Systematics and Evolution'
      issn = '1759-6831'
      msid = 'JSE-2017-12-137'
      fill_manuscript_info(name: journal, issn: issn, msid: msid)
      click_button 'Import Manuscript Metadata'
      expect(page).to have_field('title',
                                 with: 'Leaf and infructescence fossils of Alnus (Betulaceae) from the late Eocene ' \
        'of the southeastern Qinghai-Tibetan Plateau',
                                 wait: 40)
      # The autofill just populates info into the database and then displays the info from the database on the page.
      # We already have unit tests for population into the database and also tests for field display on the entry page,
      # so this is just a basic test to be sure population is happening.
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
      stub_request(:get, 'https://api.datadryad.example.org/api/v1/journals/1742-5689')
        .with(
          headers: {
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: {
          "fullName": 'Journal of The Royal Society Interface',
          "issn": '1742-5689',
          "allowReviewWorkflow": true,
          "allowEmbargo": true,
          "allowBlackout": false
        }.to_json, headers: {})

      journal = 'Journal of The Royal Society Interface'
      doi = '10.1098/rsif.2017.0030'
      fill_crossref_info(name: journal, doi: doi)
      click_import_article_metadata
      expect(page).to have_field('title',
                                 with: 'High-skilled labour mobility in Europe before and after the 2004 enlargement',
                                 wait: 20)
    end

    it 'gives message for no doi filled in' do
      journal = ''
      doi = ''
      fill_crossref_info(name: journal, doi: doi)
      click_import_article_metadata
      expect(page.find('div#population-warnings')).to have_content('Please fill in the form completely', wait: 15)
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
      page.execute_script("$('#internal_datum_do_import').val('true')")

      click_button 'Import Article Metadata'
    end

  end
end
