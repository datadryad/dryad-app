require 'spec_helper'

module Stash
  describe Harvester do
    it 'runs on a configurable schedule'
    it 'logs each request'
    it 'logs each request result'
    it 'logs all errors'
  end

  module Harvester
    describe OAIPMH do

      describe 'harvesting:' do
        it 'harvests metadata from OAI-PMH:' do
          # see ListRecordsTask
        end
        it 'harvests by datestamp range' do
          # see ListRecordsTask
        end
        it 'honors the repository time granularity' do
          # see ListRecordsConfig#to_s(Time)
        end
      end

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
        it 'supports resumptionTokens:' do
          # see ListRecordsTask#list_records
        end
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
