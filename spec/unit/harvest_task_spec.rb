require 'spec_helper'

module Dash2
  module Harvester

    describe HarvestTask do
      describe '#new' do
        it 'accepts a valid repository URL' do
          valid_url = 'http://example.org/oai'
          harvest_task = HarvestTask.new oai_base_url: valid_url
          expect(harvest_task.oai_base_uri).to eq(URI.parse(valid_url))
        end

        it 'accepts a URI object as a repository URL' do
          uri = URI.parse('http://example.org/oai')
          harvest_task = HarvestTask.new oai_base_url: uri
          expect(harvest_task.oai_base_uri).to eq(uri)
        end

        it 'rejects an invalid repository URL' do
          invalid_url = 'I am not a valid URL'
          expect { HarvestTask.new oai_base_url: invalid_url }.to raise_error(URI::InvalidURIError)
        end

        it 'requires a repository URL' do
          # noinspection RubyArgCount
          expect { HarvestTask.new }.to raise_error(ArgumentError)
        end

        it 'accepts a valid "from" datestamp' do
          time = Time.new
          harvest_task = HarvestTask.new oai_base_url: 'http://example.org/oai', from_time: time
          expect(harvest_task.from_time).to eq(time)
        end

        it 'accepts a valid "until" datestamp' do
          time = Time.new
          harvest_task = HarvestTask.new oai_base_url: 'http://example.org/oai', until_time: time
          expect(harvest_task.until_time).to eq(time)
        end

        it 'rejects datestamps that would create an invalid range' do
          epoch = Time.at(0)
          now = Time.new

          expect { HarvestTask.new oai_base_url: 'http://example.org/oai', from_time: now, until_time: epoch }.to raise_error(RangeError)
        end

        it 'accepts a metadata prefix' do
          prefix = 'datacite'
          harvest_task = HarvestTask.new oai_base_url: 'http://example.org/oai', metadata_prefix: prefix
          expect(harvest_task.metadata_prefix).to eq(prefix)
        end

        it 'rejects an invalid metadata prefix'

        it 'requires a metadata prefix to consist only of RFC 2396 URI unreserved characters' do
          reserved_rfc_2396 = ';/?:@&=+$,' # prefix must be URI unreserved characters
          reserved_rfc_2396.each_char do |c|
            invalid_prefix = "oai_#{c}"
            expect { HarvestTask.new oai_base_url: 'http://example.org/oai', metadata_prefix: invalid_prefix }.to raise_error(ArgumentError)
          end
        end

        it 'defaults to Dublin Core if no metadata prefix is set' do
          harvest_task = HarvestTask.new oai_base_url: 'http://example.org/oai'
          expect(harvest_task.metadata_prefix).to eq('oai_dc')
        end

      end
    end

    describe '#harvest' do

      before(:each) do
        @oai_client = instance_double(OAI::Client)
        @uri = 'http://example.org/oai'
        expect(OAI::Client).to receive(:new).with(@uri) {@oai_client}
      end

      it 'sends a LoadRecords request' do
        harvest_task = HarvestTask.new oai_base_url: @uri
        expect(@oai_client).to receive(:list_records)
        harvest_task.harvest
      end

      # it 'returns the ListRecords response' do
      #   result = instance_double(OAI::ListRecordsResponse)
      #   harvest_task = HarvestTask.new oai_base_url: @uri
      #   expect(@oai_client).to receive(:list_records) { result }
      #   expect(harvest_task.harvest).to be(result)
      # end

      it 'transforms the ListRecords response into something useful'

      it 'defaults to "oai_dc" if no metadata prefix is specified' do
        harvest_task = HarvestTask.new oai_base_url: @uri
        expect(@oai_client).to receive(:list_records).with({:metadata_prefix => 'oai_dc'})
        harvest_task.harvest
      end

      it 'sends the specified metadata prefix' do
        prefix = 'datacite'
        harvest_task = HarvestTask.new oai_base_url: @uri, metadata_prefix: prefix
        expect(@oai_client).to receive(:list_records).with({:metadata_prefix => prefix})
        harvest_task.harvest
      end

      it 'sends a "from" datestamp if one is specified' do
        time = Time.new
        harvest_task = HarvestTask.new oai_base_url: @uri, from_time: time
        expect(@oai_client).to receive(:list_records).with({:from => time, :metadata_prefix => 'oai_dc'})
        harvest_task.harvest
      end

      it 'sends an "until" datestamp if one is specified' do
        time = Time.new
        harvest_task = HarvestTask.new oai_base_url: @uri, until_time: time
        expect(@oai_client).to receive(:list_records).with({:until => time, :metadata_prefix => 'oai_dc'})
        harvest_task.harvest
      end

      it 'sends both datestamps if both are specified' do
        start_time = Time.new
        end_time = Time.new
        harvest_task = HarvestTask.new oai_base_url: @uri, from_time: start_time, until_time: end_time
        expect(@oai_client).to receive(:list_records).with({:from => start_time, :until => end_time, :metadata_prefix => 'oai_dc'})
        harvest_task.harvest
      end
    end

  end
end

