require 'spec_helper'

module Stash
  module Harvester
    describe Config do
      describe '#new' do
        it 'requires db, source, and index config'
      end

      describe '#from_yaml' do

        before(:each) do
          yml = File.read('spec/data/config.yml')
          expect(yml).not_to be_nil
          @config = Config.from_yaml(yml)
        end

        it 'forwards to DBConfig factory methods'

        it 'forwards to IndexConfig factory methods'

        it 'forwards to SourceConfig factory methods' do
          source_config = @config.source_config
          expect(source_config).to be_a(OAI::OAISourceConfig)
          expect(source_config.source_uri).to eq(URI('http://oai.example.org/oai'))
          expect(source_config.metadata_prefix).to eq('some_prefix')
          expect(source_config.set).to eq('some_set')
          expect(source_config.seconds_granularity).to be true
        end

        it 'provides appropriate error messages for bad config factories'
      end
    end
  end
end
