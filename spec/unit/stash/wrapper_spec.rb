require 'spec_helper'

require 'nokogiri'
require 'stash/wrapper'

module Stash
  describe Wrapper do
    describe 'stash_wrapper.xsd' do
      it 'is valid' do
        schema = Nokogiri::XML::Schema(File.read('spec/data/wrapper/stash_wrapper.xsd'))
        document = Nokogiri::XML(File.read('spec/data/wrapper/stash_wrapper.xml'))
        errors = schema.validate(document)
        expect(errors.empty?).to be true
      end
    end
  end
end
