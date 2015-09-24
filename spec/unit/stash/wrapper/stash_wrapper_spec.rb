require 'spec_helper'

require 'nokogiri'
require 'rexml/element'

module Stash
  module Wrapper
    describe StashWrapper do
      describe 'stash_wrapper.xsd' do
        it 'is valid' do
          schema = Nokogiri::XML::Schema(File.read('spec/data/wrapper/stash_wrapper.xsd'))
          document = Nokogiri::XML(File.read('spec/data/wrapper/wrapper-1.xml'))
          errors = schema.validate(document)
          expect(errors.empty?).to be true
        end

        it 'validates a document' do
          schema = Nokogiri::XML::Schema(File.read('spec/data/wrapper/stash_wrapper.xsd'))
          document = Nokogiri::XML(File.read('spec/data/wrapper/wrapper-2.xml'))
          errors = schema.validate(document)
          errors.each do |e|
            puts e
          end
          expect(errors.empty?).to be true
        end
      end

      describe '#load_from_xml' do
        it 'parses an XML file' do
          data = File.read('spec/data/wrapper/wrapper-1.xml')
          xml = REXML::Document.new(data).root
          wrapper = StashWrapper.load_from_xml(xml)

          id = wrapper.identifier
          expect(id.type).to eq(IdentifierType::DOI)
          expect(id.value).to eq('10.12345/1234567890')

          admin = wrapper.stash_administrative

          version = admin.version
          expect(version.version_number).to eq(1)
          expect(version.date).to eq(Date.new(2015, 9, 8))

          license = admin.license
          expect(license.name).to eq('Creative Commons Attribution 4.0 International (CC-BY)')
          expect(license.uri).to eq(URI('https://creativecommons.org/licenses/by/4.0/legalcode'))

          embargo = admin.embargo
          expect(embargo.type).to eq(EmbargoType::DOWNLOAD)
          expect(embargo.period).to eq('6 months')
          expect(embargo.start_date).to eq(Date.new(2015, 9, 8))
          expect(embargo.end_date).to eq(Date.new(2016, 3, 7))

          inventory = admin.inventory
          expect(inventory.num_files).to eq(1)
          expect(inventory.files.size).to eq(1)

          file = inventory.files[0]
          expect(file.pathname).to eq('mydata.xlsx')
          expect(file.size_bytes).to eq(12_345_678)
          expect(file.mime_type).to eq(MIME::Type.new('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'))

          descriptive = wrapper.stash_descriptive
          expect(descriptive).to be_an(Array)
          expect(descriptive.size).to eq(1)
          desc_elem = descriptive[0]
          expect(desc_elem).to be_an(REXML::Element)

          expected_xml =
              '<dcs:resource xmlns:dcs="http://datacite.org/schema/kernel-3"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xsi:schemaLocation="http://datacite.org/schema/kernel-3
                                http://schema.datacite.org/meta/kernel-3/metadata.xsd">
                <dcs:identifier identifierType="DOI">10.12345/1234567890</dcs:identifier>
                <dcs:creators>
                  <dcs:creator>
                    <dcs:creatorName>Abrams, Stephen</dcs:creatorName>
                  </dcs:creator>
                </dcs:creators>
                <dcs:titles>
                  <dcs:title>My dataset</dcs:title>
                </dcs:titles>
                <dcs:publisher>UC Office of the President</dcs:publisher>
                <dcs:publicationYear>2016</dcs:publicationYear>
                <dcs:subjects>
                  <dcs:subject>Data literacy</dcs:subject>
                </dcs:subjects>
                <dcs:resourceType resourceTypeGeneral="Dataset">Spreadsheet</dcs:resourceType>
                <dcs:descriptions>
                  <dcs:description descriptionType="Abstract">
                    Lorum ipsum.
                  </dcs:description>
                </dcs:descriptions>
              </dcs:resource>'

          expect(desc_elem).to be_xml(expected_xml)
        end
      end

      describe '#save_to_xml' do
        it 'maps to XML' do

          # TODO: Allow mime_type: to be a string
          payload = File.read('spec/data/wrapper/wrapper-2-payload.xml')
          payload_xml = REXML::Document.new(payload).root

          wrapper = StashWrapper.new(
            identifier: Identifier.new(type: IdentifierType::DOI, value: '10.14749/1407399498'),
            version: Version.new(number: 1, date: Date.new(2013, 8, 18), note: 'Sample wrapped Datacite document'),
            license: License::CC_BY,
            embargo: Embargo.new(type: EmbargoType::DOWNLOAD, period: '1 year', start_date: Date.new(2014, 8, 18), end_date: Date.new(2013, 8, 18)),
            inventory: Inventory.new(
              files: [
                StashFile.new(pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: MIME::Type.new('text/plain')),
                StashFile.new(pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: MIME::Type.new('text/csv')),
                StashFile.new(pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: MIME::Type.new('application/x-sas-data')),
                StashFile.new(pathname: 'formats.sas7bcat', size_bytes: 78_910, mime_type: MIME::Type.new('application/x-sas-catalog')),
                StashFile.new(pathname: 'HSRC_MasterSampleII.sas', size_bytes: 11_121, mime_type: MIME::Type.new('application/x-sas')),
                StashFile.new(pathname: 'HSRC_MasterSampleII.sav', size_bytes: 31_415, mime_type: MIME::Type.new('application/x-sav')),
                StashFile.new(pathname: 'HSRC_MasterSampleII.sps', size_bytes: 16_171, mime_type: MIME::Type.new('application/x-spss')),
                StashFile.new(pathname: 'HSRC_MasterSampleII.dta', size_bytes: 81_920, mime_type: MIME::Type.new('application/x-dta')),
                StashFile.new(pathname: 'HSRC_MasterSampleII.dct', size_bytes: 212_223, mime_type: MIME::Type.new('application/x-dct')),
                StashFile.new(pathname: 'HSRC_MasterSampleII.do', size_bytes: 242_526, mime_type: MIME::Type.new('application/x-do'))
              ]),
            descriptive_elements: [payload_xml]
          )

          wrapper_xml = wrapper.save_to_xml

          File.open('spec/data/wrapper/wrapper-2-actual.xml', 'w') do |file|
            formatter = REXML::Formatters::Pretty.new
            formatter.width = 200
            formatter.compact = true
            file.write(formatter.write(wrapper_xml, ''))
          end

          expected_xml = File.read('spec/data/wrapper/wrapper-2.xml')

          # TODO: force rs: namespace prefix

          expect(wrapper_xml).to be_xml(expected_xml)
        end
      end

    end
  end
end
