require 'spec_helper'
require 'stash/harvest_and_index_job'

module Stash
  describe HarvestAndIndexJob do
    describe '#initialize' do
      it 'creates a harvest task'
      it 'creates an indexer'
    end

    describe '#harvest_and_index' do
      it 'harvests records'
      it 'indexes harvested records'
    end
  end
end
