require 'features_helper'
require 'rsolr'

describe 'solr sanitization' do

  def uuid
    @uuid ||= '12345'
  end

  def solr_url
    @solr_url ||= YAML.safe_load(File.read(SolrHelper::BLACKLIGHT_YML), [], [], true)['test']['url']
  end

  def solr
    @solr ||= RSolr.connect(url: solr_url)
  end

  def record_count
    response = solr.get('select', params: { q: '*:*' })['response']
    response['numFound']
  end

  before(:each) do
    solr.add(uuid: uuid)
    solr.commit
    expect(record_count).to eq(1)
  end

  after(:each) do
    solr.delete_by_query("uuid:#{uuid}")
    solr.commit
    expect(record_count).to eq(0)
  end

  it 'doesn\'t let you delete everything by hacking the discovery URL' do
    expect(record_count).to eq(1)

    # TODO: see http://mail-archives.apache.org/mod_mbox/lucene-dev/201710.mbox/%3CCAJEmKoC%2BeQdP-E6BKBVDaR_43fRs1A-hOLO3JYuemmUcr1R%2BTA%40mail.gmail.com%3E
  end
end
