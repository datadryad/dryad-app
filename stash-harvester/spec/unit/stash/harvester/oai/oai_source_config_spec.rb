require 'spec_helper'

module Stash
  module Harvester
    module OAI

      RESERVED_RCF_2396 = ';/?:@&=+$,'.freeze

      describe OAISourceConfig do
        describe '#new' do
          it 'accepts a valid repository URL' do
            valid_url = 'http://example.org/oai'
            config = OAISourceConfig.new oai_base_url: valid_url
            expect(config.source_uri).to eq(URI.parse(valid_url))
          end

          it 'accepts a URI object as a repository URL' do
            uri = URI.parse('http://example.org/oai')
            config = OAISourceConfig.new oai_base_url: uri
            expect(config.source_uri).to eq(uri)
          end

          it 'rejects an invalid repository URL' do
            invalid_url = 'I am not a valid URL'
            expect { OAISourceConfig.new oai_base_url: invalid_url }.to raise_error(URI::InvalidURIError)
          end

          it 'requires a repository URL' do
            # noinspection RubyArgCount
            expect { OAISourceConfig.new }.to raise_error(ArgumentError)
          end

          it 'accepts a metadata prefix' do
            prefix = 'datacite'
            config = OAISourceConfig.new(oai_base_url: 'http://example.org/oai', metadata_prefix: prefix)
            expect(config.metadata_prefix).to eq(prefix)
          end

          it 'requires a metadata prefix to consist only of RFC 2396 URI unreserved characters' do
            RESERVED_RCF_2396.each_char do |c|
              invalid_prefix = "oai_#{c}"
              expect { OAISourceConfig.new(oai_base_url: 'http://example.org/oai', metadata_prefix: invalid_prefix) }.to raise_error(ArgumentError)
            end
          end

          it 'accepts a set spec' do
            set_spec = 'path:to:some:set'
            config = OAISourceConfig.new(oai_base_url: 'http://example.org/oai', set: set_spec)
            expect(config.set).to eq(set_spec)
          end

          it 'requires each set spec element to consist only of RFC 2396 URI unreserved characters' do
            RESERVED_RCF_2396.each_char do |c|
              next if c == ':' # don't confuse the tokenizer
              invalid_element = "set_#{c}"
              invalid_spec = "path:to:#{invalid_element}:whoops"
              expect { OAISourceConfig.new(oai_base_url: 'http://example.org/oai', set: invalid_spec) }.to raise_error(ArgumentError)
            end
          end

          it 'defaults to Dublin Core if no metadata prefix is set' do
            config = OAISourceConfig.new(oai_base_url: 'http://example.org/oai')
            expect(config.metadata_prefix).to eq('oai_dc')
          end

        end

        describe '#description' do
          it 'includes the oai_base_url' do
            valid_url = 'http://example.org/oai'
            config = OAISourceConfig.new oai_base_url: valid_url
            expect(config.description).to include(valid_url)
          end

          it 'includes the metadata prefix' do
            prefix = 'datacite'
            config = OAISourceConfig.new(oai_base_url: 'http://example.org/oai', metadata_prefix: prefix)
            expect(config.description).to include(prefix)
          end

          it 'includes the set spec' do
            set_spec = 'path:to:some:set'
            config = OAISourceConfig.new(oai_base_url: 'http://example.org/oai', set: set_spec)
            expect(config.description).to include(set_spec)
          end

          it 'includes the granularity' do
            prefix = 'oai_dc'
            config = OAISourceConfig.new(oai_base_url: 'http://example.org/oai', metadata_prefix: prefix, seconds_granularity: true)
            expect(config.description).to include('true')
          end
        end
      end

    end
  end
end
