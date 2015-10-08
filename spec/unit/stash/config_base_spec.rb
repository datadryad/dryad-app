require 'spec_helper'

module Stash
  module Harvester
    describe ConfigBase do

      class MockConfig < ConfigBase
        CONFIG_KEY = 'mock_config'
      end

      describe 'config_class_name' do
        it 'constructs a fully qualified class name from a namespace' do
          expect(MockConfig.config_class_name('Foo')).to eq('Stash::Harvester::Foo::FooMockConfig')
        end

        it 'uppercases lower-case class prefixes' do
          expect(MockConfig.config_class_name('foo')).to eq('Stash::Harvester::Foo::FooMockConfig')
        end
        
        it 'camel-cases snake-case class prefixes' do
          expect(MockConfig.config_class_name('foo_bar')).to eq('Stash::Harvester::FooBar::FooBarMockConfig')
        end

      end
    end
  end
end
