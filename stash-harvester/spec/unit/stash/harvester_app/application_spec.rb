require 'spec_helper'
require 'stash/harvester_app'
require 'webmock/rspec'

require 'tmpdir'
require 'fileutils'
require 'digest'

module Stash
  class MockDBConfig < PersistenceConfig
    can_build_if { |config| config.key?(:adapter) }

    attr_reader :connection_info

    def initialize(**connection_info)
      @connection_info = connection_info
    end

    def description
      info_desc = connection_info.map { |k, v| "#{k}: #{v}" }.join(', ')
      "#{self.class} (#{info_desc})"
    end
  end

  module HarvesterApp

    describe Application do

      attr_reader :config
      attr_reader :update_uri

      before(:all) do
        WebMock.disable_net_connect!
      end

      before(:each) do
        @config = Config.allocate

        @update_uri = URI('http://stash.example.org/stash/datasets/')
        allow(config).to receive(:update_uri).and_return(update_uri)

        @persistence_config = instance_double(PersistenceConfig).as_null_object
        allow(config).to receive(:persistence_config).and_return(@persistence_config)

        @persistence_mgr = instance_double(PersistenceManager).as_null_object
        allow(@persistence_config).to receive(:create_manager).and_return(@persistence_mgr)

        @source_config = instance_double(SourceConfig).as_null_object
        allow(config).to receive(:source_config).and_return(@source_config)

        @index_config = instance_double(Indexer::IndexConfig).as_null_object
        allow(config).to receive(:index_config).and_return(@index_config)

        @metadata_mapper = instance_double(Indexer::MetadataMapper).as_null_object
        allow(config).to receive(:metadata_mapper).and_return(@metadata_mapper)
      end

      describe '#with_config_file' do
        before :each do
          @wd = '/stash/apps/stash-harvester'
          allow(Dir).to receive(:pwd).and_return(@wd)

          @home = '/home/stash'
          allow(Dir).to receive(:home).and_return(@home)
        end

        after :each do
          allow(Dir).to receive(:pwd).and_call_original
          allow(Dir).to receive(:home).and_call_original
          allow(Config).to receive(:from_file).and_call_original
          allow(File).to receive(:exist?).and_call_original
        end

        describe '#config_file_defaults' do
          it 'prefers ./stash-harvester.yml, then ~/.stash-harvester.yml' do
            expected = %w[/stash/apps/stash-harvester/stash-harvester.yml /home/stash/.stash-harvester.yml]
            expect(Application.config_file_defaults).to eq(expected)
          end
        end

        it 'reads the specified file' do
          config_file = '/etc/stash-harvester.yml'

          # Trust the Config class to check for nonexistent files

          expect(Config).to receive(:from_file).with(config_file).and_return(config)

          app = Application.with_config_file(config_file)
          expect(app.config).to be(config)
        end

        it 'defaults to plain file in the current working directory' do
          wd_config_path = "#{@wd}/stash-harvester.yml"
          expect(File).to receive(:exist?).with(wd_config_path).and_return(true)

          expect(Config).to receive(:from_file).with(wd_config_path).and_return(config)

          app = Application.with_config_file
          expect(app.config).to be(config)
        end

        it 'falls back to dotfile in the user home directory' do
          wd_config_path = "#{@wd}/stash-harvester.yml"
          expect(File).to receive(:exist?).with(wd_config_path).and_return(false)

          home_config_path = "#{@home}/.stash-harvester.yml"
          expect(File).to receive(:exist?).with(home_config_path).and_return(true)

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
      end

      describe '#with_config' do
        it 'requires a config' do
          expect { Application.with_config }.to raise_error(ArgumentError)
        end

        it 'requires a non-nil config' do
          expect { Application.with_config(nil) }.to raise_error do |e|
            expect(e).to be_an ArgumentError
            %w[Stash::HarvesterApp::Application Stash::Config nil].each do |m|
              expect(e.message).to include(m)
            end
          end
        end

        it 'requires a usable Config object' do
          expect { Application.with_config(Object.new) }.to raise_error do |e|
            expect(e).to be_an ArgumentError
            %w[Stash::HarvesterApp::Application Stash::Config Object].each do |m|
              expect(e.message).to include(m)
            end
          end
        end

        it 'sets the config' do
          app = Application.with_config(config)
          expect(app.config).to be(config)
        end
      end

      describe '#start' do

        after(:each) do
          allow(HarvestAndIndexJob).to receive(:new).and_call_original
        end

        it 'harvests and indexes' do
          from_time = Time.utc(1914, 8, 4, 23)
          until_time = Time.utc(2018, 11, 11, 10)

          def self.mock_record(i)
            record = instance_double(Stash::Harvester::HarvestedRecord)
            allow(record).to receive(:identifier) { "record#{i}" }
            record
          end

          IndexResult = Stash::Indexer::IndexResult

          results = Array.new(3) do |i|
            record = mock_record(i)
            IndexResult.success(record)
          end

          ex = StandardError.new('oops #1')

          ex_with_backtrace = nil
          begin
            raise 'oops #2'
          rescue StandardError => e
            ex_with_backtrace = e
          end

          results << IndexResult.failure(mock_record(17), [ex, ex_with_backtrace])

          job = instance_double(HarvestAndIndexJob)
          expect(HarvestAndIndexJob).to receive(:new).with(
            update_uri: update_uri,
            source_config: @source_config,
            index_config: @index_config,
            metadata_mapper: @metadata_mapper,
            persistence_manager: @persistence_mgr,
            from_time: from_time,
            until_time: until_time
          ) { job }
          expectation = expect(job).to receive(:harvest_and_index)
          results.each do |r|
            expectation.and_yield(r)
          end

          app = Application.with_config(config)
          app.start(from_time: from_time, until_time: until_time)
        end

        it 'logs failure exceptions in a sort-friendly way'

        it 'accepts nil start and from times' do
          expect(@persistence_mgr).to receive(:find_oldest_failed_timestamp).and_return(nil)
          expect(@persistence_mgr).to receive(:find_newest_indexed_timestamp).and_return(nil)

          job = instance_double(HarvestAndIndexJob)
          expect(HarvestAndIndexJob).to receive(:new).with(
            update_uri: update_uri,
            source_config: @source_config,
            index_config: @index_config,
            metadata_mapper: @metadata_mapper,
            persistence_manager: @persistence_mgr,
            from_time: nil,
            until_time: nil
          ) { job }
          expect(job).to receive(:harvest_and_index)

          app = Application.with_config(config)
          app.start
        end

        it 'sets the datestamp of the latest success as the next start, if no failures' do
          newest_indexed = Time.utc(2016, 4, 18, 1, 2, 3)
          expect(@persistence_mgr).to receive(:find_oldest_failed_timestamp).and_return(nil)
          expect(@persistence_mgr).to receive(:find_newest_indexed_timestamp).and_return(newest_indexed)

          job = instance_double(HarvestAndIndexJob)
          expect(HarvestAndIndexJob).to receive(:new).with(
            update_uri: update_uri,
            source_config: @source_config,
            index_config: @index_config,
            metadata_mapper: @metadata_mapper,
            persistence_manager: @persistence_mgr,
            from_time: newest_indexed,
            until_time: nil
          ) { job }
          expect(job).to receive(:harvest_and_index)

          app = Application.with_config(config)
          app.start
        end

        it 'sets the datestamp of the earliest failure as the next start' do
          newest_indexed = Time.utc(2016, 4, 18, 1, 2, 3)
          allow(@persistence_mgr).to receive(:find_newest_indexed_timestamp).and_return(newest_indexed)

          oldest_failed = Time.utc(1952, 2, 6, 10, 11, 12)
          expect(@persistence_mgr).to receive(:find_oldest_failed_timestamp).and_return(oldest_failed)

          job = instance_double(HarvestAndIndexJob)
          expect(HarvestAndIndexJob).to receive(:new).with(
            update_uri: update_uri,
            source_config: @source_config,
            index_config: @index_config,
            metadata_mapper: @metadata_mapper,
            persistence_manager: @persistence_mgr,
            from_time: oldest_failed,
            until_time: nil
          ) { job }
          expect(job).to receive(:harvest_and_index)

          app = Application.with_config(config)
          app.start
        end
      end

      describe 'logging' do
        attr_reader :out

        def logged
          out.string
        end

        before(:each) do
          @out = StringIO.new
          Stash::Harvester.log_device = out
        end

        after(:each) do
          Stash::Harvester.log_device = $stdout
        end

        describe '#with_config_file' do
          it 'logs the config file used' do
            config_file = '/etc/stash-harvester.yml'
            expect(Config).to receive(:from_file).with(config_file).and_return(config)

            Application.with_config_file(config_file)
            expect(logged).to include(config_file)
          end
        end

        describe '#with_config' do
          it 'logs the configuration' do
            config = Config.from_file('spec/data/stash-harvester.yml')
            Application.with_config(config)
            aggregate_failures('config logging') do
              %i[persistence_config source_config index_config metadata_mapper].each do |c|
                desc = config.send(c).description
                expect(desc).not_to be_nil
                expect(logged).to include(desc)
              end
            end
          end
        end
      end
    end
  end
end
