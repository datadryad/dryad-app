require 'spec_helper'

require 'nokogiri'
require 'rexml/element'

module Stash
  module Wrapper
    describe StashWrapper do
      describe 'stash_wrapper.xsd' do
        it 'is valid' do
          schema = Nokogiri::XML::Schema(File.read('spec/data/wrapper/stash_wrapper.xsd'))
          document = Nokogiri::XML(File.read('spec/data/wrapper/stash_wrapper.xml'))
          errors = schema.validate(document)
          expect(errors.empty?).to be true
        end

        it 'validates a document' do
          schema = Nokogiri::XML::Schema(File.read('spec/data/wrapper/stash_wrapper.xsd'))
          document = Nokogiri::XML(File.read('spec/data/wrapper/stash-wrapper-2.xml'))
          errors = schema.validate(document)
          errors.each do |e|
            puts e
          end
          expect(errors.empty?).to be true
        end
      end

      describe '#load_from_xml' do
        it 'parses an XML file' do
          data = File.read('spec/data/wrapper/stash_wrapper.xml')
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
          expect(embargo.start).to eq(Date.new(2015, 9, 8))
          expect(embargo.end).to eq(Date.new(2016, 3, 7))

          inventory = admin.inventory
          expect(inventory.num_files).to eq(1)
          expect(inventory.files.size).to eq(1)

          file = inventory.files[0]
          expect(file.pathname).to eq('mydata.xlsx')
          expect(file.size_bytes).to eq(12345678)
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
    end
  end
end
