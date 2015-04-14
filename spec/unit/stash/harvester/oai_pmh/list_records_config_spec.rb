require 'spec_helper'

module Stash
  module Harvester
    module OAI_PMH

      describe ListRecordsConfig do
        describe '#new' do
          it 'accepts a valid "from" datestamp' do
            time = Time.new.utc
            harvest_options = ListRecordsConfig.new(from_time: time)
            expect(harvest_options.from_time).to eq(time)
          end

          it 'accepts a valid "until" datestamp' do
            time = Time.new.utc
            harvest_options = ListRecordsConfig.new(until_time: time)
            expect(harvest_options.until_time).to eq(time)
          end

          it 'rejects datestamps that would create an invalid range' do
            epoch = Time.at(0).utc
            now = Time.new.utc

            expect { ListRecordsConfig.new(from_time: now, until_time: epoch) }.to raise_error(RangeError)
          end

          it 'rejects non-UTC datestamps' do
            non_utc = Time.new(2002, 10, 31, 2, 2, 2, '+02:00')
            expect { ListRecordsConfig.new(from_time: non_utc) }.to raise_error(ArgumentError)
            expect { ListRecordsConfig.new(until_time: non_utc) }.to raise_error(ArgumentError)
          end

          it 'accepts a metadata prefix' do
            prefix = 'datacite'
            harvest_options = ListRecordsConfig.new(metadata_prefix: prefix)
            expect(harvest_options.metadata_prefix).to eq(prefix)
          end

          it 'requires a metadata prefix to consist only of RFC 2396 URI unreserved characters' do
            reserved_rfc_2396 = ';/?:@&=+$,' # prefix must be URI unreserved characters
            reserved_rfc_2396.each_char do |c|
              invalid_prefix = "oai_#{c}"
              expect { ListRecordsConfig.new(metadata_prefix: invalid_prefix) }.to raise_error(ArgumentError)
            end
          end

          it 'defaults to Dublin Core if no metadata prefix is set' do
            harvest_options = ListRecordsConfig.new
            expect(harvest_options.metadata_prefix).to eq('oai_dc')
          end

          it 'logs a warning when converting sub-day datestamps to day granularity'
        end
      end

    end
  end
end
