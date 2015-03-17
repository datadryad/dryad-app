require 'spec_helper'

module Dash2
  describe Harvester do
    describe 'its OAI-PMH harvesting' do
      it 'harvests metadata from OAI-PMH'
      it 'sends appropriate User-Agent and From headers'
      it 'runs on a configurable schedule'
      it 'harvests by datestamp range'
      it 'honors the repository time granularity'
      it 'overlaps date ranges'
      it 'starts from the datestamp of the last successfully indexed record'
      it 'records the datestamp of the last successfully indexed record'
      it 'in the event of a "partial success", records the datestamp of the first failed record'
      it 'handles resumptionTokens'
      it 'handles badResumptionToken errors'
      it 'handles resumptionTokens with expirationDates'
      it 'allows callers to select a metadata format'
      it 'respects the repository supported metadata formats'
      it 'follows 302 Found redirects with Location header'
      it 'handles 4xx errors gracefully'
      it 'handles 5xx errors gracefully'
      it 'handles OAI-PMH error responses gracefully'
      it 'logs each request'
      it 'logs each request result'
    end
    describe 'its Solr indexing' do
      it 'indexes metadata into Solr'
      it 'logs each request'
      it 'logs each request result'
      it '(...does other necessary stuff TBD...)'
    end

  end
end
