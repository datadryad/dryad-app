require 'spec_helper'
require 'stash/harvester_app'

require 'tmpdir'
require 'fileutils'
require 'digest'

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
          @config = Config.allocate

          @persistence_config = instance_double(PersistenceConfig)
          allow(@config).to receive(:persistence_config) { @persistence_config }

          @persistence_mgr = instance_double(PersistenceManager).as_null_object
          allow(@persistence_config).to receive(:create_manager) { @persistence_mgr }

          @source_config = instance_double(SourceConfig)
          allow(@config).to receive(:source_config) { @source_config }

          @index_config = instance_double(Indexer::IndexConfig)
          allow(@config).to receive(:index_config) { @index_config }

          @metadata_mapper = instance_double(Indexer::MetadataMapper)
          allow(@config).to receive(:metadata_mapper) { @metadata_mapper }
        end

        after(:each) do
          allow(HarvestAndIndexJob).to receive(:new).and_call_original
        end

        it 'harvests and indexes' do
          from_time = Time.utc(1914, 8, 4, 23)
          until_time = Time.utc(2018, 11, 11, 10)

          job = instance_double(HarvestAndIndexJob)
          expect(HarvestAndIndexJob).to receive(:new).with(
            source_config: @source_config,
            index_config: @index_config,
            metadata_mapper: @metadata_mapper,
            persistence_manager: @persistence_mgr,
            from_time: from_time,
            until_time: until_time
          ) { job }
          expect(job).to receive(:harvest_and_index)

          app = Application.with_config(@config)
          app.start(from_time: from_time, until_time: until_time)
        end

        it 'sets the datestamp of the earliest failure as the next start'
        it 'sets the datestamp of the latest success as the next start, if no failures'
        it 'bases success/failure datestamp determination only on the most recent harvest job'

        it 'logs the from_time and until_time'
        it 'sets from_time, if specified'
        it 'sets until_time, if specified'
        it 'reads from_time from the database, if not specified'
        it 'defaults until_time to now, if not specified'
      end
    end
  end
end
