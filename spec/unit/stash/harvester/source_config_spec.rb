require 'spec_helper'

module Stash
  module Harvester
    describe SourceConfig do
      describe '#for_protocol' do
        it 'understands OAI' do
          expect(SourceConfig.for_protocol('OAI')).to be(OAI::OAISourceConfig)
        end

        it 'understands Resync' do
          expect(SourceConfig.for_protocol('Resync')).to be(Resync::ResyncSourceConfig)
        end

        it 'fails for bad protocols' do
          bad_protocol = 'Elvis'
          expect { SourceConfig.for_protocol(bad_protocol) }.to raise_error do |e|
            expect(e).to be_a(NameError)
            expect(e.name).to include(bad_protocol)
          end
        end

        it 'works for new protocols' do
          module Foo
            class FooSourceConfig < SourceConfig
            end
          end
          expect(SourceConfig.for_protocol('Foo')).to be(Foo::FooSourceConfig)
        end
      end
    end
  end
end
