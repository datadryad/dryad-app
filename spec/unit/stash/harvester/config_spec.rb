require 'spec_helper'

module Stash
  module Harvester
    describe Config do
      describe '#new' do
        it 'requires db, source, and index config'
      end

      describe '#from_file' do
        it 'forwards to appropriate config factories'
        it 'provides appropriate error messages for bad config factories'
      end
    end
  end
end
