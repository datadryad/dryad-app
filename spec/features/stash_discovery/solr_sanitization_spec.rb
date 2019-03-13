require 'rails_helper'
require 'rsolr'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'SolrSanitization', type: :feature do

  before(:all) do
    # Start Solr - shutdown is handled globally when all tests have finished
    SolrInstance.instance

    solr_url = YAML.safe_load(File.read(SolrInstance::BLACKLIGHT_YML), [], [], true)['test']['url']
    @solr = RSolr.connect(url: solr_url)

    @uuid = Faker::Crypto.sha1
  end

  before(:each) do
    @solr.add(uuid: @uuid)
    @solr.commit
  end

  after(:each) do
    @solr.delete_by_query("uuid:#{@uuid}")
    @solr.commit
  end

  it 'added the record' do
    expect(@solr.get('select', params: { q: '*:*' })['response']['numFound']).to eq(1)
  end

  it 'doesn\'t let you delete everything by hacking the discovery URL' do
    expect(@solr.get('select', params: { q: '*:*' })['response']['numFound']).to eq(1)

    # TODO: see http://mail-archives.apache.org/mod_mbox/lucene-dev/201710.mbox/%3CCAJEmKoC%2BeQdP-E6BKBVDaR_43fRs1A-hOLO3JYuemmUcr1R%2BTA%40mail.gmail.com%3E
  end

end
# rubocop:enable Metrics/BlockLength
