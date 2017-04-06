require 'spec_helper'

module Stash
  module Harvester
    describe SourceConfig do

      describe '#build_from' do
        it 'reads a valid OAI config' do
          base_url = 'http://oai.datacite.org/oai'
          prefix = 'oai_datacite'
          set = 'REFQUALITY'
          seconds = false
          hash = { protocol: 'OAI', oai_base_url: base_url, metadata_prefix: prefix, set: set, seconds_granularity: seconds }
          config = SourceConfig.build_from(hash)
          expect(config).to be_a(OAI::OAISourceConfig)
          expect(config.metadata_prefix).to eq(prefix)
          expect(config.source_uri).to eq(URI(base_url))
          expect(config.set).to eq(set)
          expect(config.seconds_granularity).to eq(seconds)
        end

        it 'reads a setless OAI config' do
          base_url = 'http://oai.datacite.org/oai'
          prefix = 'oai_datacite'
          seconds = false
          hash = { protocol: 'OAI', oai_base_url: base_url, metadata_prefix: prefix, seconds_granularity: seconds }
          config = SourceConfig.build_from(hash)
          expect(config).to be_a(OAI::OAISourceConfig)
          expect(config.metadata_prefix).to eq(prefix)
          expect(config.source_uri).to eq(URI(base_url))
          expect(config.set).to be_nil
          expect(config.seconds_granularity).to eq(seconds)
        end

        it 'reads a valid Resync config' do
          cap_list_url = 'http://localhost:8888/capabilitylist.xml'
          hash = { protocol: 'Resync', capability_list_url: cap_list_url }
          config = SourceConfig.build_from(hash)
          expect(config).to be_a(Resync::ResyncSourceConfig)
          expect(config.source_uri).to eq(URI(cap_list_url))
        end
      end

      describe '#create_harvest_task' do
        it 'is abstract' do
          config = SourceConfig.new(source_url: URI('http://example.org/source'))
          expect { config.create_harvest_task }.to raise_error(NoMethodError)
        end

        it 'creates an OAIHarvestTask' do
          base_url = 'http://oai.datacite.org/oai'
          prefix = 'oai_datacite'
          set = 'REFQUALITY'
          seconds = false
          hash = { protocol: 'OAI', oai_base_url: base_url, metadata_prefix: prefix, set: set, seconds_granularity: seconds }
          config = SourceConfig.build_from(hash)
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
          config = SourceConfig.build_from(hash)
          from_time = Time.utc(2014, 1, 1)
          until_time = Time.utc(2015, 1, 1)
          task = config.create_harvest_task(from_time: from_time, until_time: until_time)
          expect(task).to be_a(Stash::Harvester::Resync::ResyncHarvestTask)
          expect(task.config).to eq(config)
          expect(task.from_time).to be_time(from_time)
          expect(task.until_time).to be_time(until_time)
        end
      end

      describe '#description' do
        it 'is abstract' do
          config = SourceConfig.new(source_url: 'http://example.org/')
          expect { config.description }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
