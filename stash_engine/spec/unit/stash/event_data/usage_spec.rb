require 'spec_helper'

module Stash
  module EventData
    describe Usage do

      before(:each) do
        @usage = Usage.new(doi: 'doi:54321/09876')

        fake_results = [
          { 'attributes' => { 'relation-type-id' => 'total-dataset-investigations-regular', 'total' => 1 } },
          { 'attributes' => { 'relation-type-id' => 'total-dataset-investigations-machine', 'total' => 2 } },
          { 'attributes' => { 'relation-type-id' => 'total-dataset-requests-regular', 'total' => 4 } },
          { 'attributes' => { 'relation-type-id' => 'total-dataset-requests-machine', 'total' => 8 } },
          { 'attributes' => { 'relation-type-id' => 'unique-dataset-investigations-regular', 'total' => 16 } },
          { 'attributes' => { 'relation-type-id' => 'unique-dataset-investigations-machine', 'total' => 32 } },
          { 'attributes' => { 'relation-type-id' => 'unique-dataset-requests-regular', 'total' => 64 } },
          { 'attributes' => { 'relation-type-id' => 'unique-dataset-requests-machine', 'total' => 128 } }
        ]

        allow(@usage).to receive(:query).and_return(fake_results)
      end

      describe :initializes do
        it 'removes prefix from doi' do
          expect(@usage.doi).to eq('54321/09876')
        end
      end

      describe :counts do
        it 'calculates unique investigations count' do
          expect(@usage.unique_dataset_investigations_count).to eq(48)
        end

        it 'calculates unique requests count' do
          expect(@usage.unique_dataset_requests_count).to eq(192)
        end
      end
    end
  end
end
