require_relative '../../../stash/stash_engine/lib/stash/datacite_metadata'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  RSpec.describe DataciteMetadata do
    include Mocks::Datacite

    # https://doi.org/10.1111/mec.13594

    before(:each) do
      mock_datacite!
      @meta = Stash::DataciteMetadata.new(doi: '10.1111/mec.13594')
      @meta.raw_metadata
    end

    describe '#raw_metadata' do
      it 'handles json parse errors' do
        WebMock.reset!
        stub_request(:get, %r{doi\.org/10\.1111%2Fmec\.13594})
          .with(
            headers: {
              'Accept' => 'application/citeproc+json',
              'Host' => 'doi.org',
              'User-Agent' => /.*/
            }
          ).to_return(status: 200, body: '<!DOCTYPE html><html><head></head><body>Awesome webpage instead.</body></html>', headers: {})
        @meta = Stash::DataciteMetadata.new(doi: '10.1111/mec.13594')
        expect(@meta.raw_metadata).to be_falsey
      end
    end

    describe '#journal' do
      it 'returns the journal from container-title' do
        expect(@meta.journal).to eq('Molecular Ecology')
      end
    end

    describe '#html_citation' do
      it 'contains the journal name' do
        expect(@meta.html_citation).to include('Molecular Ecology')
      end
    end
  end
end
