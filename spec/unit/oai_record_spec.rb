require 'spec_helper'
require 'oai/client'
require 'rexml/document'
require 'rexml/xpath'

module Dash2
  module Harvester

    describe OAIRecord do

      before(:each) do
        file = File.new( 'spec/data/oai-datacite-32153-datacite.xml' )
        doc = REXML::Document.new file
        @resource = REXML::XPath.first(doc, '/OAI-PMH/GetRecord/record/metadata/resource')
        @record = OAIRecord.new(OAI::GetRecordResponse.new(doc).record)
      end

      it 'extracts the metadata' do
        expect(@record.metadata_root).to eq(@resource)
      end

      it 'extracts the identifier' do
        expect(@record.identifier).to eq('oai:oai.datacite.org:32153')
      end

      it 'converts datestamps to Time objects' do
        expected = Time.utc(2011, 6, 8, 8, 57, 11)
        expect(@record.datestamp).to eq(expected)
      end

      it 'identifies deleted records as deleted' do
        file = File.new( 'spec/data/oai-datacite-22-oai_dc.xml' )
        doc = REXML::Document.new file
        deleted_record = OAIRecord.new(OAI::GetRecordResponse.new(doc).record)
        expect(deleted_record.deleted?).to be_truthy
      end

      it 'identifies undeleted records as undeleted' do
        expect(@record.deleted?).to be_falsey
      end

    end

  end
end
