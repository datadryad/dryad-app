require 'spec_helper'
require 'fileutils'

module Stash
  module Harvester
    describe Config do
      describe '#new' do
        it 'requires db, source, and index config' do
          args = {
            connection_info: {},
            source_config: instance_double(SourceConfig),
            index_config: instance_double(IndexConfig),
            metadata_config: instance_double(MetadataConfig)
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

      describe '#from_yaml' do

        before(:each) do
          yml = File.read('spec/data/stash-harvester.yml')
          expect(yml).not_to be_nil
          @config = Config.from_yaml(yml)
        end

        it 'extracts the DB connection info' do
          connection_info = @config.connection_info
          expect(connection_info['adapter']).to eq('sqlite3')
          expect(connection_info['database']).to eq(':memory:')
          expect(connection_info['pool']).to eq(5)
          expect(connection_info['timeout']).to eq(5000)
        end

        it 'extracts the IndexConfig' do
          index_config = @config.index_config
          expect(index_config).to be_a(Solr::SolrIndexConfig)
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

        it 'extracts the SourceConfig' do
          source_config = @config.source_config
          expect(source_config).to be_a(OAI::OAISourceConfig)
          expect(source_config.source_uri).to eq(URI('http://oai.example.org/oai'))
          expect(source_config.metadata_prefix).to eq('some_prefix')
          expect(source_config.set).to eq('some_set')
          expect(source_config.seconds_granularity).to be true
        end

        it 'provides appropriate error messages for bad config sections' do
          good_values = [/oai.example.org/, /solr.example.org/, /proxy.example.com/]
          bad_value = "'I am not a valid hostname'"
          good_values.each do |good_value|
            bad_yml = File.read('spec/data/stash-harvester.yml').sub(good_value, bad_value)
            expect { Config.from_yaml(bad_yml) }.to raise_error do |e|
              expect(e).to be_an ArgumentError
              expect(e.message).to include(bad_value)
              expect(e.cause).to be_a URI::InvalidURIError
            end
          end
        end

        it 'provides appropriate error message for invalid source protocol' do
          bad_yml = File.read('spec/data/stash-harvester.yml').sub(/OAI/, 'BadProtocol')
          expect { Config.from_yaml(bad_yml) }.to raise_error do |e|
            expect(e).to be_an ArgumentError
            expect(e.message).to include('BadProtocol')
            expect(e.cause).to be_a NameError
          end
        end

        it 'provides appropriate error message for invalid index adapter' do
          bad_yml = File.read('spec/data/stash-harvester.yml').sub(/solr/, 'BadAdapter')
          expect { Config.from_yaml(bad_yml) }.to raise_error do |e|
            expect(e).to be_an ArgumentError
            expect(e.message).to include('BadAdapter')
            expect(e.cause).to be_a NameError
          end
        end
      end

      describe '#from_file' do
        it 'reads a file' do
          @config = Config.from_file('spec/data/stash-harvester.yml')

          connection_info = @config.connection_info
          expect(connection_info['adapter']).to eq('sqlite3')
          expect(connection_info['database']).to eq(':memory:')
          expect(connection_info['pool']).to eq(5)
          expect(connection_info['timeout']).to eq(5000)

          index_config = @config.index_config
          expect(index_config).to be_a(Solr::SolrIndexConfig)
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
          expect(source_config).to be_a(OAI::OAISourceConfig)
          expect(source_config.source_uri).to eq(URI('http://oai.example.org/oai'))
          expect(source_config.metadata_prefix).to eq('some_prefix')
          expect(source_config.set).to eq('some_set')
          expect(source_config.seconds_granularity).to be true
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
            err = IOError.new('the message')
            begin
              allow(File).to receive(:read).with(path).and_raise(err)
              expect { Config.from_file(path) }.to raise_error do |e|
                expect(e).to be_an IOError
                expect(e.message).to eq(err.message)
              end
            ensure
              allow(File).to receive(:read).and_call_original
            end
          end
        end
      end

    end
  end
end
