require 'db_spec_helper'

module Stash
  module Harvester
    module Models
      describe HarvestedRecord do

        before :each do
          # load spec/fixtures/harvested_record_spec.yml
        end

        describe '#find_last_indexed' do
          it 'finds only index-completed records'
          it 'finds only the most recent such record'
        end

        describe '#find_last_indexed' do
          it 'finds only index-failed records'
          it 'finds only the oldest such record'
        end
      end
    end
  end
end
