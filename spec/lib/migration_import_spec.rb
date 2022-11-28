require 'rails_helper'
require 'tasks/migration_import'
require_relative '../support/helpers/ror_helper'
require 'time'

# rubocop:disable Layout/LineLength
RSpec.describe Tasks::MigrationImport do

  include RorHelper

  describe 'imports sample migration file' do

    before(:each) do

      mock_query(query: 'Max%20Planck%20Institute%20of%20Neurobiology', file: 'ror_response1.json')
      mock_query(query: 'University%20of%20California%20San%20Francisco', file: 'ror_response2.json')
      mock_query(query: 'Ludwig-Maximillians%20University', file: 'ror_response3.json')
      mock_query(query: 'BGI-Shenzhen', file: 'ror_response4.json')
      mock_query(query: 'University%20Hospital%20M%C3%BCnster,%20M%C3%BCnster', file: 'ror_response5.json')
      mock_query(query: 'Max%20Planck%20Institute%20of%20Immunobiology%20and%20Epigenetics', file: 'ror_response6.json')

      record_hash = JSON.parse(File.read(StashEngine::Engine.root.join('spec', 'data', 'migration_input.json')))

      id_importer = Tasks::MigrationImport::Identifier.new(hash: record_hash)
      id_importer.import
      @identifier = StashEngine::Identifier.all.last
    end

    xit 'imports a sample dataset -- identifier set' do
      expect(@identifier.identifier).to eq('10.7272/Q6RX997G')
      expect(@identifier.storage_size).to eq(5_168_709)
    end

    xit 'has resources' do
      expect(@identifier.resources.count).to eq(2)
      expect(@identifier.resources.first.slice('created_at', 'has_geolocation', 'download_uri',
                                               'update_uri', 'title', 'publication_date', 'accepted_agreement',
                                               'tenant_id', 'skip_datacite_update', 'skip_emails', 'loosen_validation',
                                               'solr_indexed', 'preserve_curation_status', 'hold_for_peer_review',
                                               'peer_review_end_date', 'old_resource_id')).to eq(
                                                 'created_at' => Time.parse('Mon, 21 Aug 2017 17:55:41 UTC +00:00'),
                                                 'has_geolocation' => true,
                                                 'download_uri' => 'http://merritt.cdlib.org/d/ark%3A%2Fb7272%2Fq6rx997g',
                                                 'update_uri' => 'http://uc3-mrtsword-prd.cdlib.org:39001/mrtsword/edit/ucsf_lib_datashare/doi%3A10.7272%2FQ6RX997G',
                                                 'title' => 'Gut Microbiota from Multiple Sclerosis patients triggers spontaneous autoimmune encephalomyelitis in mice --16S data--',
                                                 'publication_date' => Time.parse('Mon, 02 Oct 2017 07:00:00 UTC +00:00'),
                                                 'accepted_agreement' => nil,
                                                 'tenant_id' => 'ucop',
                                                 'skip_datacite_update' => true,
                                                 'skip_emails' => true,
                                                 'loosen_validation' => false,
                                                 'solr_indexed' => false,
                                                 'preserve_curation_status' => false,
                                                 'hold_for_peer_review' => false,
                                                 'peer_review_end_date' => nil,
                                                 'old_resource_id' => nil
                                               )
    end

    xit 'has subsidiary objects and some spot checks of objects off the resource' do
      res = @identifier.resources.first
      expect(res.authors.count).to eq(2)
      expect(res.data_files.count).to eq(2)
      expect(res.edit_histories.count).to eq(1)
      expect(res.stash_version.version).to eq(1)
      # expect(res.share.secret_id.length).to eq(43)
      expect(res.user.orcid).to eq('0000-0003-0067-194X')
      expect(res.current_resource_state.resource_state).to eq('submitted')
      expect(res.curation_activities.length).to eq(1)
      expect(res.curation_activities.first.status).to eq('published')
      expect(res.repo_queue_states.length).to eq(1)
      expect(res.publication_years.length).to eq(1)
      expect(res.publisher.publisher).to eq('UC San Francisco')
      expect(res.descriptions.length).to eq(3)
      expect(res.contributors.length).to eq(3)
      expect(res.datacite_dates.first.date).to eq('2017-10-02T07:00:00Z')
      expect(res.geolocations.length).to eq(3)
      expect(res.geolocations.first.geolocation_place.geo_location_place).to eq('Germany')
      expect(res.geolocations.first.geolocation_point.latitude).to eq(0.51196755e2)
      expect(res.geolocations.first.geolocation_box.sw_latitude).to eq(0.47270352e2)
      expect(res.related_identifiers.length).to eq(1)
      expect(res.resource_type.resource_type_general).to eq('dataset')
      expect(res.rights.first.rights_uri).to eq('https://creativecommons.org/licenses/by/4.0/')
      expect(res.sizes.first.size).to eq('18421')
      expect(res.subjects.length).to eq(3)
    end

  end
end
# rubocop:enable Layout/LineLength
