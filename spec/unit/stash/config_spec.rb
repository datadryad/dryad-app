require 'spec_helper'
require 'fileutils'

module Stash

  class MockDBConfig < PersistenceConfig
    can_build_if { |config| config.key?(:adapter) }

    attr_reader :connection_info

    def initialize(**connection_info)
      @connection_info = connection_info
    end
  end

  describe Config do
    describe '#new' do
      it 'requires db, source, and index config' do
        args = {
          connection_info: {},
          source_config: instance_double(Harvester::SourceConfig),
          index_config: instance_double(Indexer::IndexConfig)
        }
        args.each do |k, _v|
          args_copy = args.clone
          args_copy.delete(k)
          expect do
            # noinspection RubyArgCount
            Config.new(args_copy)
          end.to raise_error(ArgumentError)
        end
      end
    end

    describe '#from_env' do

      before(:each) do
        env = ::Config::Factory::Environment.load_file('spec/data/stash-harvester.yml')
        @config = Config.from_env(env)
      end

      it 'builds a PersistenceConfig' do
        persistence_config = @config.persistence_config
        connection_info = persistence_config.connection_info
        expect(connection_info[:adapter]).to eq('sqlite3')
        expect(connection_info[:database]).to eq(':memory:')
        expect(connection_info[:pool]).to eq(5)
        expect(connection_info[:timeout]).to eq(5000)
      end

      it 'builds a IndexConfig' do
        index_config = @config.index_config
        expect(index_config).to be_an(Indexer::Solr::SolrIndexConfig)
        expect(index_config.uri).to eq(URI('http://solr.example.org/'))
        expect(index_config.proxy_uri).to eq(URI('http://foo:bar@proxy.example.com/'))

        opts = index_config.opts
        expect(opts[:url]).to eq('http://solr.example.org/')
        expect(opts[:proxy]).to eq('http://foo:bar@proxy.example.com/')
        expect(opts[:open_timeout]).to eq(120)
        expect(opts[:read_timeout]).to eq(300)
        expect(opts[:retry_503]).to eq(3)
        expect(opts[:retry_after_limit]).to eq(20)
      end

      it 'builds a SourceConfig' do
        source_config = @config.source_config
        expect(source_config).to be_a(Harvester::OAI::OAISourceConfig)
        expect(source_config.source_uri).to eq(URI('http://oai.example.org/oai'))
        expect(source_config.metadata_prefix).to eq('some_prefix')
        expect(source_config.set).to eq('some_set')
        expect(source_config.seconds_granularity).to be true
      end

      it 'builds a MetadataMapper' do
        metadata_mapper = @config.metadata_mapper
        expect(metadata_mapper).to be_a(Indexer::DataciteGeoblacklight::Mapper)
      end

      it 'provides appropriate error messages for bad config sections' do
        good_values = [/oai.example.org/, /solr.example.org/, /proxy.example.com/]
        bad_value = "'I am not a valid hostname'"
        good_values.each do |good_value|
          bad_yml = File.read('spec/data/stash-harvester.yml').sub(good_value, bad_value)
          env = ::Config::Factory::Environment.load_hash(YAML.load(bad_yml))
          expect { Config.from_env(env) }.to raise_error do |e|
            expect(e).to be_a URI::InvalidURIError
            expect(e.message).to include(bad_value)
          end
        end
      end

      it 'provides appropriate error message for invalid source protocol' do
        bad_yml = File.read('spec/data/stash-harvester.yml').sub(/OAI/, 'BadProtocol')
        env = ::Config::Factory::Environment.load_hash(YAML.load(bad_yml))
        expect { Config.from_env(env) }.to raise_error do |e|
          expect(e).to be_an ArgumentError
          expect(e.message).to include('BadProtocol')
        end
      end

      it 'provides appropriate error message for invalid index adapter' do
        bad_yml = File.read('spec/data/stash-harvester.yml').sub(/Solr/, 'BadAdapter')
        env = ::Config::Factory::Environment.load_hash(YAML.load(bad_yml))
        expect { Config.from_env(env) }.to raise_error do |e|
          expect(e).to be_an ArgumentError
          expect(e.message).to include('BadAdapter')
        end
      end

      it 'provides appropriate error message for invalid metadata mapper' do
        bad_yml = File.read('spec/data/stash-harvester.yml').sub(/datacite_geoblacklight/, 'bad_mapper')
        env = ::Config::Factory::Environment.load_hash(YAML.load(bad_yml))
        expect { Config.from_env(env) }.to raise_error do |e|
          expect(e).to be_an ArgumentError
          expect(e.message).to include('bad_mapper')
        end
      end
    end

    describe '#from_file' do
      it 'reads a file' do
        @config = Config.from_file('spec/data/stash-harvester.yml')

        persistence_config = @config.persistence_config
        connection_info = persistence_config.connection_info
        expect(connection_info[:adapter]).to eq('sqlite3')
        expect(connection_info[:database]).to eq(':memory:')
        expect(connection_info[:pool]).to eq(5)
        expect(connection_info[:timeout]).to eq(5000)

        index_config = @config.index_config
        expect(index_config).to be_a(Indexer::Solr::SolrIndexConfig)
        expect(index_config.uri).to eq(URI('http://solr.example.org/'))
        expect(index_config.proxy_uri).to eq(URI('http://foo:bar@proxy.example.com/'))

        opts = index_config.opts
        expect(opts[:url]).to eq('http://solr.example.org/')
        expect(opts[:proxy]).to eq('http://foo:bar@proxy.example.com/')
        expect(opts[:open_timeout]).to eq(120)
        expect(opts[:read_timeout]).to eq(300)
        expect(opts[:retry_503]).to eq(3)
        expect(opts[:retry_after_limit]).to eq(20)

        source_config = @config.source_config
        expect(source_config).to be_a(Harvester::OAI::OAISourceConfig)
        expect(source_config.source_uri).to eq(URI('http://oai.example.org/oai'))
        expect(source_config.metadata_prefix).to eq('some_prefix')
        expect(source_config.set).to eq('some_set')
        expect(source_config.seconds_granularity).to be true

        metadata_mapper = @config.metadata_mapper
        expect(metadata_mapper).to be_a(Indexer::DataciteGeoblacklight::Mapper)
      end

      it 'raises an IOError for nonexistent files' do
        nonexistent_file = Tempfile.new('foo')
        nonexistent_path = nonexistent_file.path
        nonexistent_file.unlink

        expect { Config.from_file(nonexistent_path) }.to raise_error do |e|
          expect(e).to be_an IOError
          expect(e.message).to include(nonexistent_path)
        end
      end

      it 'raises an IOError for non-files' do
        Dir.mktmpdir do |non_file_path|
          expect { Config.from_file(non_file_path) }.to raise_error do |e|
            expect(e).to be_an IOError
            expect(e.message).to include(non_file_path)
          end
        end
      end

      it 'raises an IOError for non-readable files' do
        Dir.mktmpdir do |tmpdir|
          unreadable_path = "#{tmpdir}/config.yml"
          FileUtils.touch(unreadable_path)
          File.chmod(0000, unreadable_path)
          expect { Config.from_file(unreadable_path) }.to raise_error do |e|
            expect(e).to be_an IOError
            expect(e.message).to include(unreadable_path)
          end
        end
      end

      it 'raises an IOError for malformed files' do
        bad_yaml = "\t"
        Dir.mktmpdir do |tmpdir|
          bad_yaml_path = "#{tmpdir}/config.yml"
          File.open(bad_yaml_path, 'w') do |f|
            f.write(bad_yaml)
          end
          expect { Config.from_file(bad_yaml_path) }.to raise_error do |e|
            expect(e).to be_an IOError
            expect(e.message).to include(bad_yaml_path)
          end
        end
      end

      it 'forwards IOErrors for unreadable files' do
        Dir.mktmpdir do |tmpdir|
          path = "#{tmpdir}/whatever.yml"
          FileUtils.touch(path)
          expect { Config.from_file(path) }.to raise_error do |e|
            expect(e).to be_an IOError
            expect(e.message).to include(path)
          end
        end
      end
    end

  end
end
