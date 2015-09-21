require 'spec_helper'

require 'nokogiri'
require 'stash/wrapper'

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
          expect(id.type).to eq(Identifier::DOI)
          expect(id.value).to eq('10.12345/1234567890')
        end
      end
    end
  end
end
