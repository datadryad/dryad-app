require 'spec_helper'

describe StashEngine do
  describe 'setup' do
    it 'yields self' do
      StashEngine.setup do |x|
        expect(x).to be(StashEngine)
      end
    end
  end
end

module StashEngine
  describe Engine do
    attr_reader :config
    attr_reader :configuration
    attr_reader :application

    before(:each) do
      @config = double(Rails::Application::Configuration)
      @application = double(Rails::Application)
      allow(application).to receive(:config).and_return(config)
      allow(Rails).to receive(:application).and_return(application)
    end

    describe 'static assets' do
      it 'uses ActionDispatch::Static when public_file_server.enabled is true' do
        allow(config).to receive(:public_file_server).and_return({ enabled: true }.to_ostruct)

        initializers = Engine.initializers
        initializer = initializers.find { |init| init.name == 'static assets' }
        expect(initializer).not_to be_nil

        context = double(Engine)
        initializer.instance_variable_set(:@context, context)
        allow(context).to receive(:root).and_return('/stash_engines/stash_engine')

        middleware = double(Rails::Configuration::MiddlewareStackProxy)
        allow(application).to receive(:middleware).and_return(middleware)

        expect(middleware).to receive(:insert_before).with(::ActionDispatch::Static, ::ActionDispatch::Static, '/stash_engines/stash_engine/public')
        initializer.run(application)
      end

      it 'doesn\'t inject middleware when public_file_server.enabled is false' do
        allow(config).to receive(:public_file_server).and_return({ enabled: false }.to_ostruct)

        initializers = Engine.initializers
        initializer = initializers.find { |init| init.name == 'static assets' }
        expect(initializer).not_to be_nil

        expect(application).not_to receive(:middleware)
        initializer.run(application)
      end
    end
  end
end
