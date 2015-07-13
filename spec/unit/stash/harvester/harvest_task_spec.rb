require 'spec_helper'

module Stash
  module Harvester
    describe HarvestTask do
      describe '#new' do
        it 'accepts a valid "from" datestamp' do
          time = Time.new.utc
          config = HarvestTask.new(from_time: time)
          expect(config.from_time).to eq(time)
        end

        it 'accepts a valid "until" datestamp' do
          time = Time.new.utc
          config = HarvestTask.new(until_time: time)
          expect(config.until_time).to eq(time)
        end

        it 'rejects datestamps that would create an invalid range' do
          epoch = Time.at(0).utc
          now = Time.new.utc

          expect { HarvestTask.new(from_time: now, until_time: epoch) }.to raise_error(RangeError)
        end

        it 'rejects non-UTC datestamps' do
          non_utc = Time.new(2002, 10, 31, 2, 2, 2, '+02:00')
          expect { HarvestTask.new(from_time: non_utc) }.to raise_error(ArgumentError)
          expect { HarvestTask.new(until_time: non_utc) }.to raise_error(ArgumentError)
        end

      end
    end
  end
end
