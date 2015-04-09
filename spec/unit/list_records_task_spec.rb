require 'spec_helper'

module Stash
  module Harvester
    describe ListRecordsTask do
      describe '#new' do
        it 'accepts a valid repository URL' do
          valid_url = 'http://example.org/oai'
          task = ListRecordsTask.new oai_base_url: valid_url
          expect(task.oai_base_uri).to eq(URI.parse(valid_url))
        end

        it 'accepts a URI object as a repository URL' do
          uri = URI.parse('http://example.org/oai')
          task = ListRecordsTask.new oai_base_url: uri
          expect(task.oai_base_uri).to eq(uri)
        end

        it 'rejects an invalid repository URL' do
          invalid_url = 'I am not a valid URL'
          expect { ListRecordsTask.new oai_base_url: invalid_url }.to raise_error(URI::InvalidURIError)
        end

        it 'requires a repository URL' do
          # noinspection RubyArgCount
          expect { ListRecordsTask.new }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#list_records' do
      before(:each) do
        @oai_client = instance_double(OAI::Client)
        @uri = 'http://example.org/oai'
        expect(OAI::Client).to receive(:new).with(@uri) { @oai_client }
      end

      it 'sends a ListRecords request' do
        task = ListRecordsTask.new oai_base_url: @uri
        expect(@oai_client).to receive(:list_records)
        task.list_records
      end

      it 'maps the ListRecords response as a sequence of Stash::Havester::OAIRecord objects' do
        require 'rexml/document'

        file = File.new('spec/data/oai-datacite-list-records-june-2011-oai_dc.xml')
        doc = REXML::Document.new file
        result = OAI::ListRecordsResponse.new(doc) {} # empty resumption block
        expected_array = result.collect { |r| OAIRecord.new(r) }

        task = ListRecordsTask.new oai_base_url: @uri
        expect(@oai_client).to receive(:list_records) { result }

        harvested_array = task.list_records.to_a
        expect(harvested_array).to eq(expected_array)
      end

      it 'returns an empty enumerable if no response is returned' do
        task = ListRecordsTask.new oai_base_url: @uri
        expect(@oai_client).to receive(:list_records) { nil }
        harvested_array = task.list_records.to_a
        expect(harvested_array).to eq([])
      end

      it 'defaults to "oai_dc" if no metadata prefix is specified' do
        task = ListRecordsTask.new oai_base_url: @uri
        expect(@oai_client).to receive(:list_records).with(metadata_prefix: 'oai_dc')
        task.list_records
      end

      it 'sends the specified metadata prefix' do
        prefix = 'datacite'
        task = ListRecordsTask.new oai_base_url: @uri, config: ListRecordsConfig.new(metadata_prefix: prefix)
        expect(@oai_client).to receive(:list_records).with(metadata_prefix: prefix)
        task.list_records
      end

      it 'sends a "from" datestamp if one is specified' do
        time = Time.new.utc
        task = ListRecordsTask.new oai_base_url: @uri, config: ListRecordsConfig.new(from_time: time, seconds_granularity: true)
        expect(@oai_client).to receive(:list_records).with(from: time, metadata_prefix: 'oai_dc')
        task.list_records
      end

      it 'sends an "until" datestamp if one is specified' do
        time = Time.new.utc
        task = ListRecordsTask.new oai_base_url: @uri, config: ListRecordsConfig.new(until_time: time, seconds_granularity: true)
        expect(@oai_client).to receive(:list_records).with(until: time, metadata_prefix: 'oai_dc')
        task.list_records
      end

      it 'sends both datestamps if both are specified' do
        start_time = Time.new.utc
        end_time = Time.new.utc
        task = ListRecordsTask.new oai_base_url: @uri, config: ListRecordsConfig.new(from_time: start_time, until_time: end_time, seconds_granularity: true)
        expect(@oai_client).to receive(:list_records).with(from: start_time, until: end_time, metadata_prefix: 'oai_dc')
        task.list_records
      end

      it 'sends datestamps at day granularity unless otherwise specified' do
        start_time = Time.new.utc
        end_time = Time.new.utc
        task = ListRecordsTask.new oai_base_url: @uri, config: ListRecordsConfig.new(from_time: start_time, until_time: end_time)
        expect(@oai_client).to receive(:list_records).with(from: start_time.strftime('%Y-%m-%d'), until: end_time.strftime('%Y-%m-%d'), metadata_prefix: 'oai_dc')
        task.list_records
      end

      it 'supports resumption' do
        require 'rexml/document'

        file_1 = File.new('spec/data/resumption-1.xml')
        file_2 = File.new('spec/data/resumption-2.xml')
        file_full = File.new('spec/data/resumption-full.xml')

        doc_1 = REXML::Document.new file_1
        doc_2 = REXML::Document.new file_2
        doc_full = REXML::Document.new file_full

        result_paged = OAI::ListRecordsResponse.new(doc_1) do
          OAI::ListRecordsResponse.new(doc_2)
        end

        result_full = OAI::ListRecordsResponse.new(doc_full)
        expected_array = result_full.collect { |r| OAIRecord.new(r) }

        task = ListRecordsTask.new oai_base_url: @uri
        expect(@oai_client).to receive(:list_records) { result_paged }

        harvested_array = task.list_records.to_a
        expect(harvested_array).to match_array(expected_array)
      end

      it 'is lazy' do
        require 'rexml/document'

        file_1 = File.new('spec/data/resumption-1.xml')
        doc_1 = REXML::Document.new file_1

        result_paged = OAI::ListRecordsResponse.new(doc_1) do
          raise "resumption block shouldn't get called if we never iterate beyond the first result"
        end

        expect(@oai_client).to receive(:list_records) { result_paged }
        task = ListRecordsTask.new oai_base_url: @uri
        all_records = task.list_records

        some_records = all_records.take(5).to_a
        expect(some_records.size).to eq(5)
      end

      it 'respects 503 with Retry-After' # see https://github.com/code4lib/ruby-oai/issues/45

    end
  end
end
