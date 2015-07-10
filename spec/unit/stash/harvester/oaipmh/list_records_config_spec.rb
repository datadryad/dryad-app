require 'spec_helper'

module Stash
  module Harvester
    module OAIPMH

      RESERVED_RCF_2396 = ';/?:@&=+$,'

      describe ListRecordsConfig do
        describe '#new' do
          it 'accepts a valid "from" datestamp' do
            time = Time.new.utc
            config = ListRecordsConfig.new(from_time: time)
            expect(config.from_time).to eq(time)
          end

          it 'accepts a valid "until" datestamp' do
            time = Time.new.utc
            config = ListRecordsConfig.new(until_time: time)
            expect(config.until_time).to eq(time)
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
            config = ListRecordsConfig.new(metadata_prefix: prefix)
            expect(config.metadata_prefix).to eq(prefix)
          end

          it 'requires a metadata prefix to consist only of RFC 2396 URI unreserved characters' do
            RESERVED_RCF_2396.each_char do |c|
              invalid_prefix = "oai_#{c}"
              expect { ListRecordsConfig.new(metadata_prefix: invalid_prefix) }.to raise_error(ArgumentError)
            end
          end

          it 'accepts a set spec' do
            set_spec = 'path:to:some:set'
            config = ListRecordsConfig.new(set_spec: set_spec)
            expect(config.set_spec).to eq(set_spec)
          end

          it 'requires each set spec element to consist only of RFC 2396 URI unreserved characters' do
            RESERVED_RCF_2396.each_char do |c|
              next if c == ':' # don't confuse the tokenizer
              invalid_element = "set_#{c}"
              invalid_spec = "path:to:#{invalid_element}:whoops"
              expect { ListRecordsConfig.new(metadata_prefix: invalid_spec) }.to raise_error(ArgumentError)
            end
          end

          it 'defaults to Dublin Core if no metadata prefix is set' do
            config = ListRecordsConfig.new
            expect(config.metadata_prefix).to eq('oai_dc')
          end

          it 'logs a warning when converting sub-day datestamps to day granularity'
        end
      end

    end
  end
end
