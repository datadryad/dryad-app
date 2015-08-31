require 'spec_helper'
require 'oai/client'
require 'rexml/document'

module Stash
  module Harvester
    module OAI

      describe OAIRecord do

        before(:each) do
          @file = 'spec/data/oai/oai-datacite-32153-datacite.xml'
          @doc = REXML::Document.new File.new(@file)
          @record = OAIRecord.new(::OAI::GetRecordResponse.new(@doc).record)
        end

        it 'extracts the metadata' do
          datacite_resource = REXML::XPath.first(@doc, '/OAI-PMH/GetRecord/record/metadata/resource')
          expect(@record.metadata_root).to eq(datacite_resource)
        end

        it 'extracts the content' do
          datacite_resource_xml = File.read('spec/data/oai/oai-datacite-32153-datacite-resource.xml')
          content = @record.content
          expect(content).to be_a(String)
          expect(content).to be_xml(datacite_resource_xml)
        end

        it 'returns nil metadata for deleted records' do
          file = File.new('spec/data/oai/oai-datacite-22-oai_dc.xml')
          doc = REXML::Document.new file
          deleted_record = OAIRecord.new(::OAI::GetRecordResponse.new(doc).record)
          expect(deleted_record.metadata_root).to be_nil
        end

        it 'extracts the identifier' do
          expect(@record.identifier).to eq('oai:oai.datacite.org:32153')
        end

        it 'converts datestamps to Time objects' do
          expected = Time.utc(2011, 6, 8, 8, 57, 11)
          expect(@record.timestamp).to eq(expected)
        end

        it 'identifies deleted records as deleted' do
          file = File.new('spec/data/oai/oai-datacite-22-oai_dc.xml')
          doc = REXML::Document.new file
          deleted_record = OAIRecord.new(::OAI::GetRecordResponse.new(doc).record)
          expect(deleted_record.deleted?).to be_truthy
        end

        it 'identifies undeleted records as undeleted' do
          expect(@record.deleted?).to be_falsey
        end

        describe '#==' do
          it 'treats identical records as equal' do
            expect(@record).to eq(@record)
          end

          it 'treats equal records as equal' do
            equal_doc = REXML::Document.new File.new(@file)
            equal_record = OAIRecord.new(::OAI::GetRecordResponse.new(equal_doc).record)

            expect(@record).to eq(equal_record)
            expect(equal_record).to eq(@record)
          end

          it 'treats records with different datestamps as different' do
            record2 = OAIRecord.new(::OAI::GetRecordResponse.new(@doc).record)
            datestamp = Time.now
            expect(record2).to receive(:timestamp).at_least(:once) { datestamp }
            expect(@record).to_not eq(record2)
            expect(record2).to_not eq(@record)
          end

          it 'treats records with different identifiers as different' do
            record2 = OAIRecord.new(::OAI::GetRecordResponse.new(@doc).record)
            expect(record2).to receive(:identifier).at_least(:once) { 'elvis' }
            expect(@record).to_not eq(record2)
            expect(record2).to_not eq(@record)
          end

          it 'treats records with different metadata as different' do
            file = File.new('spec/data/oai/oai-datacite-32153-oai_dc.xml')
            doc = REXML::Document.new file
            dc_record = OAIRecord.new(::OAI::GetRecordResponse.new(doc).record)
            expect(@record).to_not eq(dc_record)
            expect(dc_record).to_not eq(@record)
          end

          it 'treats deleted records as different from undeleted records' do
            record2 = OAIRecord.new(::OAI::GetRecordResponse.new(@doc).record)
            expect(record2).to receive(:deleted?).at_least(:once) { true }
            expect(@record).to_not eq(record2)
            expect(record2).to_not eq(@record)
          end
        end
      end

    end
  end
end
