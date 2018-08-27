require 'spec_helper'

module Stash
  module EventData
    describe Usage do

      before(:each) do
        @usage = Usage.new(doi: 'doi:54321/09876')

        fake_results =
          [
            {
              'id' => 'unique-dataset-investigations-regular', # 16 count
              'year-months' => [
                { 'id' => '2018-07', 'sum' => 3 },
                { 'id' => '2018-08', 'sum' => 13 }
              ]
            },
            {
              'id' => 'unique-dataset-investigations-machine', # 32 count
              'year-months' => [
                { 'id' => '2018-07', 'sum' => 5 },
                { 'id' => '2018-08', 'sum' => 27 }
              ]
            },
            {
              'id' => 'unique-dataset-requests-regular', # 64 count
              'year-months' => [
                { 'id' => '2018-07', 'sum' => 11 },
                { 'id' => '2018-08', 'sum' => 53 }
              ]
            },
            {
              'id' => 'unique-dataset-requests-machine', # 128 count
              'year-months' => [
                { 'id' => '2018-07', 'sum' => 37 },
                { 'id' => '2018-08', 'sum' => 91 }
              ]
            }
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
