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
      end

      describe '#load_from_xml' do
        it 'parses an XML file' do
          data = File.read('spec/data/wrapper/stash_wrapper.xml')
          xml = REXML::Document.new(data).root
          wrapper = StashWrapper.load_from_xml(xml)

          id = wrapper.identifier
          expect(id.type).to eq(IdentifierType::DOI)
          expect(id.value).to eq('10.12345/1234567890')

          # TODO: other elements

          descriptive = wrapper.stash_descriptive
          expect(descriptive).to be_an(Array)
          expect(descriptive.size).to eq(1)
          desc_elem = descriptive[0]
          expect(desc_elem).to be_an(REXML::Element)

          # TODO: more assertions
        end
      end
    end
  end
end
