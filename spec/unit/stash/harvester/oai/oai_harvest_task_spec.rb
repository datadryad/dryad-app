require 'spec_helper'

module Stash
  module Harvester
    module OAI

      describe OAIHarvestTask do
        before(:each) do
          @uri = 'http://example.org/oai'
          @config = OAISourceConfig.new(oai_base_url: @uri)
        end

        describe '#new' do
          it 'accepts a valid "from" datestamp' do
            time = Time.new.utc
            config = OAIHarvestTask.new(config: @config, from_time: time)
            expect(config.from_time).to eq(time)
          end

          it 'accepts a valid "until" datestamp' do
            time = Time.new.utc
            config = OAIHarvestTask.new(config: @config, until_time: time)
            expect(config.until_time).to eq(time)
          end

          it 'rejects datestamps that would create an invalid range' do
            epoch = Time.at(0).utc
            now = Time.new.utc

            expect { OAIHarvestTask.new(config: @config, from_time: now, until_time: epoch) }.to raise_error(RangeError)
          end

          it 'rejects non-UTC datestamps' do
            non_utc = Time.new(2002, 10, 31, 2, 2, 2, '+02:00')
            expect { OAIHarvestTask.new(config: @config, from_time: non_utc) }.to raise_error(ArgumentError)
            expect { OAIHarvestTask.new(config: @config, until_time: non_utc) }.to raise_error(ArgumentError)
          end
        end

        describe '#harvest_records' do
          before(:each) do
            @oai_client = instance_double(::OAI::Client)
            expect(::OAI::Client).to receive(:new).with(@uri) { @oai_client }
          end

          it 'sends a ListRecords request' do
            task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri))
            expect(@oai_client).to receive(:list_records)
            task.harvest_records
          end

          it "maps the ListRecords response as a sequence of #{OAIRecord} objects" do
            require 'rexml/document'

            file = File.new('spec/data/oai/oai-datacite-list-records-june-2011-oai_dc.xml')
            doc = REXML::Document.new file
            result = ::OAI::ListRecordsResponse.new(doc) {} # empty resumption block
            expected_array = result.collect { |r| OAIRecord.new(r) }

            task = OAIHarvestTask.new(config: @config)
            expect(@oai_client).to receive(:list_records) { result }

            harvested_array = task.harvest_records.to_a
            expect(harvested_array).to eq(expected_array)
          end

          it 'returns an empty enumerable if no response is returned' do
            task = OAIHarvestTask.new(config: @config)
            expect(@oai_client).to receive(:list_records) { nil }
            harvested_array = task.harvest_records.to_a
            expect(harvested_array).to eq([])
          end

          it 'defaults to "oai_dc" if no metadata prefix is specified' do
            task = OAIHarvestTask.new(config: @config)
            expect(@oai_client).to receive(:list_records).with(metadata_prefix: 'oai_dc')
            task.harvest_records
          end

          it 'sends the specified metadata prefix' do
            prefix = 'datacite'
            task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri, metadata_prefix: prefix))
            expect(@oai_client).to receive(:list_records).with(metadata_prefix: prefix)
            task.harvest_records
          end

          it 'sends a set spec if one is specified' do
            task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri, set: 'some:set:spec'))
            expect(@oai_client).to receive(:list_records).with(metadata_prefix: 'oai_dc', set: 'some:set:spec')
            task.harvest_records
          end

          it 'sends a "from" datestamp if one is specified' do
            time = Time.new.utc
            task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri, seconds_granularity: true), from_time: time)
            expect(@oai_client).to receive(:list_records).with(from: time, metadata_prefix: 'oai_dc')
            task.harvest_records
          end

          it 'sends an "until" datestamp if one is specified' do
            time = Time.new.utc
            task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri, seconds_granularity: true), until_time: time)
            expect(@oai_client).to receive(:list_records).with(until: time, metadata_prefix: 'oai_dc')
            task.harvest_records
          end

          it 'sends both datestamps if both are specified' do
            start_time = Time.new.utc
            end_time = Time.new.utc
            task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri, seconds_granularity: true), from_time: start_time, until_time: end_time)
            expect(@oai_client).to receive(:list_records).with(from: start_time, until: end_time, metadata_prefix: 'oai_dc')
            task.harvest_records
          end

          it 'sends datestamps at day granularity unless otherwise specified' do
            start_time = Time.new.utc
            end_time = Time.new.utc
            task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri), from_time: start_time, until_time: end_time)
            expect(@oai_client).to receive(:list_records).with(from: start_time.strftime('%Y-%m-%d'), until: end_time.strftime('%Y-%m-%d'), metadata_prefix: 'oai_dc')
            task.harvest_records
          end

          it 'supports resumption' do
            require 'rexml/document'

            file_1 = File.new('spec/data/oai/resumption-1.xml')
            file_2 = File.new('spec/data/oai/resumption-2.xml')
            file_full = File.new('spec/data/oai/resumption-full.xml')

            doc_1 = REXML::Document.new file_1
            doc_2 = REXML::Document.new file_2
            doc_full = REXML::Document.new file_full

            result_paged = ::OAI::ListRecordsResponse.new(doc_1) do
              ::OAI::ListRecordsResponse.new(doc_2)
            end

            result_full = ::OAI::ListRecordsResponse.new(doc_full)
            expected_array = result_full.collect { |r| OAIRecord.new(r) }

            task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri))
            expect(@oai_client).to receive(:list_records) { result_paged }

            harvested_array = task.harvest_records.to_a
            expect(harvested_array).to match_array(expected_array)
          end

          it 'is lazy' do
            require 'rexml/document'

            file_1 = File.new('spec/data/oai/resumption-1.xml')
            doc_1 = REXML::Document.new file_1

            result_paged = ::OAI::ListRecordsResponse.new(doc_1) do
              fail "resumption block shouldn't get called if we never iterate beyond the first result"
            end

            expect(@oai_client).to receive(:list_records) { result_paged }
            task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri))
            all_records = task.harvest_records

            some_records = all_records.take(5).to_a
            expect(some_records.size).to eq(5)
          end

          describe 'error handling:' do

            before(:each) do
              @out = StringIO.new
              Harvester.log_device = @out
            end

            after(:each) do
              Harvester.log_device = $stdout
            end

            def logged
              @out.string
            end

            it 'logs errors' do
              err_msg = 'I am an error message'
              task = OAIHarvestTask.new(config: OAISourceConfig.new(oai_base_url: @uri))
              expect(@oai_client).to receive(:list_records).and_raise(err_msg)
              expect { task.harvest_records }.to raise_error(RuntimeError) do |e|
                expect(e.message).to include(err_msg)
              end
              expect(logged).to include(err_msg)
            end

            it 'handles OAI-PMH error responses gracefully'
            it 'treats an "empty list" ::OAI::Exception as an empty list'
            it 'follows 302 Found redirects with Location header'
            it 'handles 4xx errors gracefully'
            it 'handles 5xx errors gracefully'
            it 'respects 503 with Retry-After' # see https://github.com/code4lib/ruby-oai/issues/45
          end

          it 'logs a warning when converting sub-day datestamps to day granularity'

        end
      end

    end
  end
end
