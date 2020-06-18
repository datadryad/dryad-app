require 'rails_helper'

describe StashDatacite do
  attr_reader :application
  attr_reader :app_config
  attr_reader :app_root

  before(:each) do
    @application = double(Rails::Application)
    allow(Rails).to receive(:application).and_return(application)

    @app_config = double(Rails::Application::Configuration)
    allow(application).to receive(:config).and_return(app_config)
    @app_root = Rails::Paths::Root.new('/apps/stash/')
    allow(application).to receive(:root).and_return(app_root)

    allow(app_config).to(receive(:to_prepare)) { |&block| block.call }
  end

  describe '#config_resource_patch' do
    it 'associates the resource patch' do
      expect(StashDatacite::ResourcePatch).to receive(:associate_with_resource).with(StashEngine::Resource)
      StashDatacite.config_resource_patch
    end
  end

  describe StashDatacite::Engine do
    it 'appends migrations in an initializer' do
      initializers = StashDatacite::Engine.initializers
      initializer = initializers.find { |init| init.name == :append_migrations }
      expect(initializer).not_to be_nil

      context = double(StashDatacite::Engine)
      engine_root = Rails::Paths::Root.new('/apps/stash_engines/stash_datacite')
      allow(context).to receive(:root).and_return(engine_root)
      engine_config = double(Rails::Application::Configuration)
      engine_root.add('db/migrate')
      allow(engine_config).to receive(:paths).and_return(engine_root)
      allow(context).to receive(:config).and_return(engine_config)

      app_root.add('db/migrate')
      allow(app_config).to receive(:paths).and_return(app_root)

      initializer.instance_variable_set(:@context, context)
      initializer.run(application)

      app_paths = app_config.paths['db/migrate']
      expect(app_paths).to include('/apps/stash_engines/stash_datacite/db/migrate')
    end
  end
end
