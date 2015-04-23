require 'acceptance/acceptance_helper'

module Stash
  describe Harvester do
    it 'runs on a configurable schedule'
    it 'logs each request'
    it 'logs each request result'
    it 'logs all errors'

    describe 'README' do
      it 'documents OAI-PMH support in detail'
      it 'makes it clear we\'re at least hypothetically protocol-agnostic'
    end

    describe 'Gemspec' do
      it 'makes it clear we\'re at least hypothetically protocol-agnostic'
      it '\'s suitable for submitting to Ruby-Gems'
    end

  end
end
