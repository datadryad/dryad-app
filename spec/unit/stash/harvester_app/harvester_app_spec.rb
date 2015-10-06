require 'spec_helper'
require 'stash/harvester_app'

module Stash
  module HarvesterApp
    describe '#constants' do
      it "includes all constants from #{Harvester}" do
        Stash::Harvester.constants.each do |c|
          expect(HarvesterApp.const_get(c)).to be(Harvester.const_get(c))
        end
      end
    end
  end
end
