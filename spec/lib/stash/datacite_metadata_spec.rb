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
