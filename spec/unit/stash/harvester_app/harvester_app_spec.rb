require 'spec_helper'
require 'stash/harvester_app'

module Stash
  describe HarvesterApp do
    describe '#constants' do
      it "includes all constants from #{Harvester}" do
        Stash::Harvester.constants.each do |c|
          expect(HarvesterApp.const_get(c)).to be(Harvester.const_get(c))
        end
      end
    end

    it 'sets the datestamp of the earliest failure as the next start'

    it 'sets the datestamp of the latest success as the next start, if no failures'

    it 'bases success/failure datestamp determination only on the most recent harvest job'
  end
end
