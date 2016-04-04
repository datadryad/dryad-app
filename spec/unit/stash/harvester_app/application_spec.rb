require 'spec_helper'
require 'stash/harvester_app'

require 'tmpdir'
require 'fileutils'

module Stash
  module HarvesterApp
    describe Application do
      describe '#with_config_file' do
        before :each do
          @wd = '/stash/apps/stash-harvester'
          allow(Dir).to receive(:pwd) { @wd }

          @home = '/home/stash'
          allow(Dir).to receive(:home) { @home }
        end

        after :each do
          allow(Dir).to receive(:pwd).and_call_original
          allow(Dir).to receive(:home).and_call_original
          allow(Config).to receive(:from_file).and_call_original
          allow(File).to receive(:exist?).and_call_original
        end

        describe '#config_file_defaults' do
          it 'prefers ./stash-harvester.yml, then ~/.stash-harvester.yml' do
            expected = %w(/stash/apps/stash-harvester/stash-harvester.yml /home/stash/.stash-harvester.yml)
            expect(Application.config_file_defaults).to eq(expected)
          end
        end

        it 'reads the specified file' do
          config_file = '/etc/stash-harvester.yml'

          # Trust the Config class to check for nonexistent files
          config = Config.allocate
          expect(Config).to receive(:from_file).with(config_file).and_return(config)

          app = Application.with_config_file(config_file)
          expect(app.config).to be(config)
        end

        it 'defaults to plain file in the current working directory' do
          wd_config_path = "#{@wd}/stash-harvester.yml"
          expect(File).to receive(:exist?).with(wd_config_path).and_return(true)

          config = Config.allocate
          expect(Config).to receive(:from_file).with(wd_config_path).and_return(config)

          app = Application.with_config_file
          expect(app.config).to be(config)
        end

        it 'falls back to dotfile in the user home directory' do
          wd_config_path = "#{@wd}/stash-harvester.yml"
          expect(File).to receive(:exist?).with(wd_config_path).and_return(false)

          home_config_path = "#{@home}/.stash-harvester.yml"
          expect(File).to receive(:exist?).with(home_config_path).and_return(true)

          config = Config.allocate
          expect(Config).to receive(:from_file).with(home_config_path).and_return(config)

          app = Application.with_config_file
          expect(app.config).to be(config)
        end

        it 'raises ArgumentError if passed nil and no default found' do
          wd_config_path = "#{@wd}/stash-harvester.yml"
          expect(File).to receive(:exist?).with(wd_config_path).and_return(false)

          home_config_path = "#{@home}/.stash-harvester.yml"
          expect(File).to receive(:exist?).with(home_config_path).and_return(false)

          expect { Application.with_config_file }.to raise_error do |e|
            expect(e).to be_an ArgumentError
            expect(e.message).to include "#{@wd}/stash-harvester.yml"
            expect(e.message).to include "#{@home}/.stash-harvester.yml"
          end
        end

        it 'logs the config file used'
      end

      describe '#with_config' do
        it 'requires a config' do
          expect { Application.with_config }.to raise_error(ArgumentError)
        end

        it 'requires a non-nil config' do
          expect { Application.with_config(nil) }.to raise_error do |e|
            expect(e).to be_an ArgumentError
            %w(Stash::HarvesterApp::Application Stash::Config nil).each do |m|
              expect(e.message).to include(m)
            end
          end
        end

        it 'requires a usable Config object' do
          expect { Application.with_config(Object.new) }.to raise_error do |e|
            expect(e).to be_an ArgumentError
            %w(Stash::HarvesterApp::Application Stash::Config Object).each do |m|
              expect(e.message).to include(m)
            end
          end
        end

        it 'sets the config' do
          config = Config.allocate
          app = Application.with_config(config)
          expect(app.config).to be(config)
        end
      end

      describe '#initialize' do
        it 'logs the connection info'
        it 'logs the source URI'
        it 'logs the index URI'
        it 'logs the metadata mapper'
      end

      describe '#start' do
        before(:each) do
          @source_uri = URI('http://oai.example.org/oai')
          @index_uri = URI('http://solr.example.org/')

          @source_config = instance_double(Harvester::SourceConfig)
          @harvest_task = instance_double(Harvester::HarvestTask)
          allow(@source_config).to receive(:create_harvest_task) { @harvest_task }
          allow(@source_config).to receive(:source_uri) { @source_uri }

          @metadata_mapper = instance_double(Indexer::MetadataMapper)
          allow(@metadata_mapper).to receive(:desc_from) { 'foo' }
          allow(@metadata_mapper).to receive(:desc_to) { 'bar' }

          @indexer = instance_double(Indexer::Indexer)
          @index_config = instance_double(Indexer::IndexConfig)
          allow(@index_config).to receive(:create_indexer).with(@metadata_mapper) { @indexer }
          allow(@index_config).to receive(:uri) { @index_uri }

          @records = Array.new(5) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }.lazy

          @p_mgr = instance_double(PersistenceManager)

          @config = Config.allocate
          allow(@config).to receive(:persistence_manager) { p_mgr }
          allow(@config).to receive(:source_config) { @source_config }
          allow(@config).to receive(:index_config) { @index_config }
          allow(@config).to receive(:metadata_mapper) { @metadata_mapper }
        end

        it 'creates a harvest job'
        it 'creates an index job'
        it 'creates a harvested_record for each harvested record'
        it 'creates an indexed_record for each indexed record'
        it 'logs overall job failures'
        it 'sets the harvest status to failed in event of a pre-indexing failure'
        it 'sets the index status to failed in event of an indexing failure'

        it 'logs the from_time and until_time'
        it 'sets from_time, if specified'
        it 'sets until_time, if specified'
        it 'reads from_time from the database, if not specified'
        it 'defaults until_time to now, if not specified'

        it 'harvests and indexes' do
          app = Application.with_config(@config)
          expect(@harvest_task).to receive(:harvest_records) { @records }
          expect(@indexer).to receive(:index).with(@records)
          app.start
        end

        it 'sets the datestamp of the earliest failure as the next start'
        it 'sets the datestamp of the latest success as the next start, if no failures'
        it 'bases success/failure datestamp determination only on the most recent harvest job'
      end
    end
  end
end
