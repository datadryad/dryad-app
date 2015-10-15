require 'spec_helper'

module Stash
  module Harvester
    describe SourceConfig do
      describe '#for_protocol' do
        it 'understands OAI' do
          expect(SourceConfig.for_namespace('OAI')).to be(OAI::OAISourceConfig)
        end

        it 'understands Resync' do
          expect(SourceConfig.for_namespace('Resync')).to be(Resync::ResyncSourceConfig)
        end

        it 'fails for bad protocols' do
          bad_protocol = 'Elvis'
          expect { SourceConfig.for_namespace(bad_protocol) }.to raise_error do |e|
            expect(e).to be_an(ArgumentError)
            expect(e.message).to include(bad_protocol)
          end
        end

        it 'works for new protocols' do
          module Foo
            class FooSourceConfig < SourceConfig
            end
          end
          expect(SourceConfig.for_namespace('Foo')).to be(Foo::FooSourceConfig)
        end
      end

      describe '#from_hash' do
        it 'reads a valid OAI config' do
          base_url = 'http://oai.datacite.org/oai'
          prefix = 'oai_datacite'
          set = 'REFQUALITY'
          seconds = false
          hash = { protocol: 'OAI', oai_base_url: base_url, metadata_prefix: prefix, set: set, seconds_granularity: seconds }
          config = SourceConfig.from_hash(hash)
          expect(config).to be_a(OAI::OAISourceConfig)
          expect(config.metadata_prefix).to eq(prefix)
          expect(config.source_uri).to eq(URI(base_url))
          expect(config.set).to eq(set)
          expect(config.seconds_granularity).to eq(seconds)
        end

        it 'reads a valid Resync config' do
          cap_list_url = 'http://localhost:8888/capabilitylist.xml'
          hash = { protocol: 'Resync', capability_list_url: cap_list_url }
          config = SourceConfig.from_hash(hash)
          expect(config).to be_a(Resync::ResyncSourceConfig)
          expect(config.source_uri).to eq(URI(cap_list_url))
        end
      end

      describe '#create_harvest_task' do
        it 'creates an OAIHarvestTask' do
          base_url = 'http://oai.datacite.org/oai'
          prefix = 'oai_datacite'
          set = 'REFQUALITY'
          seconds = false
          hash = { protocol: 'OAI', oai_base_url: base_url, metadata_prefix: prefix, set: set, seconds_granularity: seconds }
          config = SourceConfig.from_hash(hash)
          from_time = Time.utc(2014, 1, 1)
          until_time = Time.utc(2015, 1, 1)
          task = config.create_harvest_task(from_time: from_time, until_time: until_time)
          expect(task).to be_a(Stash::Harvester::OAI::OAIHarvestTask)
          expect(task.config).to eq(config)
          expect(task.from_time).to be_time(from_time)
          expect(task.until_time).to be_time(until_time)
        end

        it 'creates a ResyncHarvestTask' do
          cap_list_url = 'http://localhost:8888/capabilitylist.xml'
          hash = { protocol: 'Resync', capability_list_url: cap_list_url }
          config = SourceConfig.from_hash(hash)
          from_time = Time.utc(2014, 1, 1)
          until_time = Time.utc(2015, 1, 1)
          task = config.create_harvest_task(from_time: from_time, until_time: until_time)
          expect(task).to be_a(Stash::Harvester::Resync::ResyncHarvestTask)
          expect(task.config).to eq(config)
          expect(task.from_time).to be_time(from_time)
          expect(task.until_time).to be_time(until_time)
        end
      end
    end
  end
end
