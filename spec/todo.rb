require 'rspec/core'
require 'stash/harvester'

# List of TODO items in spec form
module Stash

  describe Harvester do
    it 'runs on a configurable schedule'
    it 'logs each request'
    it 'logs each request result'
    it 'logs all errors'

    it 'does something intelligent with deleted resources' # insofar as we can detect them

    describe 'README' do
      it 'documents OAI-PMH support in detail'
      it 'makes it clear we\'re at least hypothetically protocol-agnostic'
    end

    describe 'Gemspec' do
      it 'makes it clear we\'re at least hypothetically protocol-agnostic'
      it '\'s suitable for submitting to Ruby-Gems'
    end
  end

  module Harvester

    describe OAIPMH do

      describe 'configuration:' do
        it 'includes the OAI-PMH base URI'
        it 'includes the repository time granularity'
      end

      describe 'scheduling:' do
        it 'overlaps date ranges'
        it 'starts from the datestamp of the last successfully indexed record'
        it 'starts at UTC midnight *before* the datestamp of the last successfully indexed record, when harvesting at day granularity'
      end

      describe 'state tracking:' do
        it 'records the datestamp of the latest successfully indexed record'
        it 'in the event of a "partial success", records the datestamp of the earliest failed record'
        it 'maintains enough state to keep track of the start/end datestamp itself'
      end

      describe 'resumption:' do
        it 'handles badResumptionToken errors'
        it 'handles resumptionTokens with expirationDates'
      end

      describe 'good citizenship:' do
        it 'sends appropriate User-Agent and From headers'
      end

      describe 'error handling:' do
        it 'handles OAI-PMH error responses gracefully'
        it 'follows 302 Found redirects with Location header'
        it 'handles 4xx errors gracefully'
        it 'handles 5xx errors gracefully'
      end
    end

    describe 'Stash::Harvester::Solr' do
      it 'indexes metadata into Solr'
      it 'logs each request'
      it 'logs each request result'
      it '(...does other necessary stuff TBD...)'
    end

  end
end
