require 'spec_helper'

describe StashDatacite do
  describe '#resource_class=' do
    before(:each) do
      application = double(Rails::Application)
      allow(Rails).to receive(:application).and_return(application)

      config = double(Rails::Application::Configuration)
      allow(application).to receive(:config).and_return(config)

      allow(config).to(receive(:to_prepare)) { |&block| block.call }
    end

    it 'sets the resource class' do
      # TODO: stop injecting this, just hard-code & load the patch in an initializer
      StashDatacite.resource_class = 'StashEngine::Resource'
      expect(StashDatacite.resource_class).to eq(StashEngine::Resource)
    end

    it 'associates the resource patch' do
      # TODO: stop injecting this, just hard-code & load the patch in an initializer
      expect(StashDatacite::ResourcePatch).to receive(:associate_with_resource).with(StashEngine::Resource)
      StashDatacite.resource_class = 'StashEngine::Resource'
    end
  end
end
