require 'spec_helper'

module StashEngine
  describe :repository do
    attr_reader :logger

    before(:each) do
      @logger = instance_double(Logger)
      allow(logger).to receive(:debug)
      allow(Rails).to receive(:logger).and_return(logger)
    end

    after(:each) do
      allow(Rails).to receive(:logger).and_call_original
    end

    it 'returns an instance of the configured repository' do
      expect(StashEngine.repository).to be_a(Stash::MockRepository)
    end
  end
end
