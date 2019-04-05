require 'rails_helper'
require 'pry'
require 'webmock/rspec'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'Populate manuscript metadata from outside source', type: :feature do

  include DatasetHelper
  include Mocks::RSolr

  before(:each) do
    mock_solr!
  end

  context :journal_metadata_autofill, js: true do
    before(:each) do
      # TODO: we probably need to figure out how to stub ORCID login/api for the entire application instead of relying on sandbox
      WebMock.disable_net_connect!(allow: ['127.0.0.1', 'api.sandbox.orcid.org'])

      # This requests stubs solr so we don't have to run it just for the home page with the latest datasets shown
      # stub_request(:get, 'http://127.0.0.1:8983/solr/geoblacklight/select?q=*:*&q.alt=*:*&rows=10&sort=timestamp%20desc&start=0&wt=ruby')
      stub_request(:get, %r{\Ahttp://127.0.0.1:8983/solr/geoblacklight/.+\z})
        .to_return(status: 200, body: '', headers: {})

      sign_in
      start_new_dataset
    end

    after(:each) do
      WebMock.disable!
    end

    it 'gives warning for bad dataset info' do
      # this stubs the old dryad api tha Daisie was calling
      stub_request(:put, 'https://api.datadryad.example.org/api/v1/journals//packages/?access_token=bad_token')
        .to_return(status: 404, body: '', headers: {})
      journal = 'European Journal of Plant Pathology'
      # issn = '1573-8469'
      manuscript = 'APPS-D-grog-plant0001221'
      find('input[value="manuscript"]').click
      fill_article_info(name: journal, msid: manuscript)
      click_button 'Import Manuscript Metadata'
      expect(page.find('div#population-warnings')).to have_content(/Could not retrieve manuscript data.+/, wait: 15)
    end
  end

  context :crossref_metadata_autofill, js: true do
    before(:each) do
      WebMock.disable_net_connect!(allow: ['127.0.0.1', 'api.sandbox.orcid.org'])

      # This requests stubs solr so we don't have to run it just for the home page with the latest datasets shown
      stub_request(:get, %r{\Ahttp://127.0.0.1:8983/solr/geoblacklight/.+\z})
        .to_return(status: 200, body: '', headers: {})

      sign_in
      start_new_dataset
    end

    after(:each) do
      WebMock.disable!
    end

    it 'works for successful dataset request to crossref' do
      stub_request(:get, 'https://api.crossref.org/works/10.1098/rsif.2017.0030')
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => /.*/,
            'User-Agent' => /.*/,
            'X-User-Agent' => /.*/
          }
        )
        .to_return(status: 200,
                   body:  File.new(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', 'crossref_response.json')),
                   headers: {})
      journal = 'Journal of The Royal Society Interface'
      doi = '10.1098/rsif.2017.0030'
      fill_crossref_info(name: journal, doi: doi)
      click_button 'Import Article Metadata'
      expect(page).to have_field('title',
                                 with: 'High-skilled labour mobility in Europe before and after the 2004 enlargement',
                                 wait: 15)
    end

    it 'gives message for no doi filled in' do
      journal = ''
      doi = ''
      fill_crossref_info(name: journal, doi: doi)
      click_button 'Import Article Metadata'
      expect(page.find('div#population-warnings')).to have_content('Please enter a DOI to import metadata', wait: 15)
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
                     body:  'not found',
                     headers: {})
      journal = 'cats'
      doi = 'scabs'
      fill_crossref_info(name: journal, doi: doi)
      click_button 'Import Article Metadata'
      expect(page.find('div#population-warnings')).to have_content( "We couldn't retrieve information from CrossRef about this DOI", wait: 15)
    end
  end
end
# rubocop:enable Metrics/BlockLength
