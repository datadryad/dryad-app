require 'spec_helper'

module Stash
  module Harvester
    module Resync
      describe ResyncSourceConfig do
        describe '#new' do
          it 'accepts a valid capability list URL' do
            valid_url = 'http://example.org/capability_list.xml'
            task = ResyncSourceConfig.new(capability_list_url: valid_url)
            expect(task.source_uri).to eq(URI.parse(valid_url))
          end

          it 'accepts a URI object as a capability list URL' do
            uri = URI.parse('http://example.org/capability_list.xml')
            task = ResyncSourceConfig.new(capability_list_url: uri)
            expect(task.source_uri).to eq(uri)
          end

          it 'rejects an invalid capability list URL' do
            invalid_url = 'I am not a valid URL'
            expect { ResyncSourceConfig.new(capability_list_url: invalid_url) }.to raise_error(URI::InvalidURIError)
          end

          it 'requires a capability list URL' do
            # noinspection RubyArgCount
            expect { ResyncSourceConfig.new }.to raise_error(ArgumentError)
          end
        end

      end
    end
  end
end
