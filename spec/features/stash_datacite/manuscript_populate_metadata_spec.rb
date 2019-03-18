require 'rails_helper'
require 'pry'
require 'webmock/rspec'

RSpec.feature 'Populate manuscript metadata from journal and manuscript id', type: :feature do

  include DatasetHelper

  before(:all) do
    # Start Solr - shutdown is handled globally when all tests have finished
    # SolrInstance.instance
    #
  end

  context 'journal-metadata-autofill', js: true do
    before(:each) do
      # TODO: we probably need to figure out how to stub ORCID login/api for the entire application instead of relying on sandbox
      WebMock.disable_net_connect!(allow: ['127.0.0.1', 'api.sandbox.orcid.org'])

      # This requests stubs solr so we don't have to run it just for the home page with the latest datasets shown
      stub_request(:get, 'http://127.0.0.1:8983/solr/geoblacklight/select?q=*:*&q.alt=*:*&rows=10&sort=timestamp%20desc&start=0&wt=ruby')
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
      fill_article_info(name: journal, msid: manuscript)
      click_button 'Import Manuscript Metadata'
      expect(page.find('div#population-warnings')).to have_content(/Could not retrieve manuscript data..+/, wait: 15)
    end
  end
end
# rubocop:enable Metrics/BlockLength
