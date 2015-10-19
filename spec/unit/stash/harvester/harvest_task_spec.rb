require 'spec_helper'

module Stash
  module Harvester
    describe HarvestTask do

      before(:each) do
        @config = SourceConfig.new(source_url: 'http://example.org/')
      end

      describe '#new' do
        it 'accepts a valid "from" datestamp' do
          time = Time.new.utc
          config = HarvestTask.new(config: @config, from_time: time)
          expect(config.from_time).to eq(time)
        end

        it 'accepts a valid "until" datestamp' do
          time = Time.new.utc
          config = HarvestTask.new(config: @config, until_time: time)
          expect(config.until_time).to eq(time)
        end

        it 'rejects datestamps that would create an invalid range' do
          epoch = Time.at(0).utc
          now = Time.new.utc

          expect { HarvestTask.new(config: @config, from_time: now, until_time: epoch) }.to raise_error(RangeError)
        end

        it 'rejects non-UTC datestamps' do
          non_utc = Time.new(2002, 10, 31, 2, 2, 2, '+02:00')
          expect { HarvestTask.new(config: @config, from_time: non_utc) }.to raise_error(ArgumentError)
          expect { HarvestTask.new(config: @config, until_time: non_utc) }.to raise_error(ArgumentError)
        end

        it 'accepts Dates as well as Times'

        it 'rejects mixed Dates and Times'

        it 'requires a config' do
          expect { HarvestTask.new }.to raise_error(ArgumentError)
        end
      end

      describe '#harvest_records' do
        it 'is abstract' do
          task = HarvestTask.new(config: @config)
          expect { task.harvest_records }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
