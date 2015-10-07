require 'spec_helper'

module Stash
  module Harvester
    module Solr
      describe SolrIndexConfig do
        describe '#new' do
          it 'requires a url' do
            expect { SolrIndexConfig.new }.to raise_error(ArgumentError)
          end

          it 'rejects an invalid url' do
            invalid_url = 'I am not a valid URL'
            expect { SolrIndexConfig.new(url: invalid_url) }.to raise_error(URI::InvalidURIError)
          end

          it 'rejects an invalid proxy_url' do
            invalid_url = 'I am not a valid URL'
            expect { SolrIndexConfig.new(url: 'http://example.org', proxy: invalid_url) }.to raise_error(URI::InvalidURIError)
          end

          it 'logs a warning if :proxy_url is used instead of :proxy' do
            logger = instance_double(Logger)
            original_logger = Harvester.log
            begin
              Harvester.log = logger
              proxy_url = 'whatever'
              expect(log).to receive(:warn).with(a_string_including('WARN', proxy_url, ':proxy'))
              SolrIndexConfig.new(url: 'http://example.org', proxy_url: proxy_url)
            rescue
              Harvester.log = original_logger
            end
          end

          it 'logs a warning if :proxy_uri is used instead of :proxy' do
            logger = instance_double(Logger)
            original_logger = Harvester.log
            begin
              Harvester.log = logger
              proxy_url = 'whatever'
              expect(log).to receive(:warn).with(a_string_including('WARN', proxy_url, ':proxy'))
              SolrIndexConfig.new(url: 'http://example.org', proxy_url: proxy_url)
            rescue
              Harvester.log = original_logger
            end
          end
        end

        describe '#uri' do
          it 'returns the URI as a URI' do
            url = 'http://example.org'
            config = SolrIndexConfig.new(url: url)
            expect(config.uri).to eq(URI(url))
          end
        end

        describe '#proxy_uri' do
          it 'returns the URI as a URI' do
            proxy_url = 'http://proxy.example.org'
            config = SolrIndexConfig.new(url: 'http://example.org/', proxy: proxy_url)
            expect(config.proxy_uri).to eq(URI(proxy_url))
          end
        end

        describe '#opts' do
          it 'captures the url as a string' do
            url = 'http://example.org'
            config = SolrIndexConfig.new(url: url)
            expect(config.opts[:url]).to eq(url)
          end

          it 'captures the proxy url as a string' do
            proxy = 'http://proxy.example.org'
            config = SolrIndexConfig.new(url: 'http://example.org/', proxy: proxy)
            expect(config.opts[:proxy]).to eq(proxy)
          end

          it 'captures arbitrary additional options' do
            config = SolrIndexConfig.new(
              url: 'http://example.org/',
              proxy: 'http://proxy.example.org',
              elvis: 'presley'
            )
            expect(config.opts[:elvis]).to eq('presley')
          end

          it 'captures arbitrary additional options when args passed as a hash' do
            opts = {
              url: 'http://example.org/',
              proxy: 'http://proxy.example.org',
              elvis: 'presley'
            }
            config = SolrIndexConfig.new(opts)
            expect(config.opts[:elvis]).to eq('presley')
          end

        end
      end
    end
  end
end
