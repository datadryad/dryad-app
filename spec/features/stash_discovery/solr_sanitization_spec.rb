require 'rails_helper'
require 'rsolr'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'SolrSanitization', type: :feature do

  include Mocks::Datacite
  include Mocks::Repository
  include Mocks::Ror
  include Mocks::Stripe

  # We can revisit this, but for now these test don't do much and just cause us testing problems.
  before(:all) do
    # Start Solr - shutdown is handled globally when all tests have finished
    # SolrInstance.instance
    # doc = YAML.load(ERB.new(File.read(File.join(Rails.root, SolrInstance::BLACKLIGHT_YML))).result)

    # @solr = RSolr.connect(url: doc['test']['url'])

    # @uuid = Faker::Crypto.sha1
  end

  after(:all) do
    # SolrInstance.instance.stop if SolrInstance.present?
  end

  before(:each) do
    # @solr.add(uuid: @uuid)
    # @solr.commit
  end

  after(:each) do
    # @solr.delete_by_query("uuid:#{@uuid}")
    # @solr.commit
  end

  xit 'added the record' do
    expect(@solr.get('select', params: { q: '*:*' })['response']['numFound']).to eq(1)
  end

  xit 'doesn\'t let you delete everything by hacking the discovery URL' do
    expect(@solr.get('select', params: { q: '*:*' })['response']['numFound']).to eq(1)

    # TODO: see http://mail-archives.apache.org/mod_mbox/lucene-dev/201710.mbox/%3CCAJEmKoC%2BeQdP-E6BKBVDaR_43fRs1A-hOLO3JYuemmUcr1R%2BTA%40mail.gmail.com%3E
  end

  describe :facets do

    before(:each) do
      mock_datacite!
      mock_repository!
      mock_ror!
      mock_stripe!

      3.times do
        resource = create(:resource_published, identifier: create(:identifier))
        resource.submit_to_solr
      end
    end

    xit 'displays 3 facets (Placename, Subject and Journal) on the Explore Data page' do
      visit search_path
      expect(page).to have_text('Placename')
      expect(page).to have_text('Subject')
      expect(page).to have_text('Journal')
    end

  end

end
# rubocop:enable Metrics/BlockLength
