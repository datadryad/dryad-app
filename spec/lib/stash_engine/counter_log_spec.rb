require_relative '../../../stash/stash_engine/lib/stash_engine/counter_log'
require 'active_support' # needed for blank? when not loaded in the rails environment
require 'active_support/core_ext/object/blank'
require 'byebug'

module StashEngine
  RSpec.describe CounterLog do
    describe 'self.log' do
      before(:each) do
        # trickiness to substitute our own stuff for a logger using the info method
        @my_counter_log = StashEngine::CounterLog
        @logger = double('some logger')
        allow(@logger).to receive(:info) do |info|
          @output = info
        end
        allow(@my_counter_log).to receive(:logger).and_return(@logger)
      end

      it 'strips out control characters inside logging fields' do
        @my_counter_log.log(['a', "big\tfat\ncat\ris\tmine", 'noober', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16'])
        outs = @output.split("\t")
        expect(outs[1]).to eq('a')
        expect(outs[2]).to eq('big fat cat is mine')
        expect(outs[3]).to eq('noober')
      end

      it 'will not log if required publication date not set' do
        @my_counter_log.log(['a', "big\tfat\ncat\ris\tmine", 'noober'])
        expect(@output).to be(nil)
      end

    end
  end
end
